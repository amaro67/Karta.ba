import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:karta_shared/karta_shared.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _isPaymentProcessing = false;
  String? _error;
  String? _checkoutUrl;
  // Store order and session IDs for potential future use (debugging, analytics, etc.)
  String? _orderId;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createCheckoutSession();
    });
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            return _handleNavigationRequest(request.url);
          },
          onPageStarted: (String url) {
            _handlePageNavigation(url);
          },
          onPageFinished: (String url) {
            _handlePageNavigation(url);
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _error = 'Failed to load checkout page: ${error.description}';
                _isLoading = false;
              });
            }
          },
        ),
      );
  }

  NavigationDecision _handleNavigationRequest(String url) {
    // Check for success redirect
    if (url.contains('/api/order/success') || url.contains('/order/success')) {
      final uri = Uri.parse(url);
      final sessionId = uri.queryParameters['session_id'];
      final orderId = uri.queryParameters['order_id'];
      
      if (sessionId != null && orderId != null) {
        _orderId = orderId;
        _sessionId = sessionId;
        _handlePaymentSuccess();
        return NavigationDecision.prevent; // Prevent navigation, we'll handle it
      }
    }
    
    // Check for cancel redirect
    if (url.contains('/api/order/cancel') || url.contains('/order/cancel')) {
      final uri = Uri.parse(url);
      final orderId = uri.queryParameters['order_id'];
      
      if (orderId != null) {
        _orderId = orderId;
        _handlePaymentCancel();
        return NavigationDecision.prevent; // Prevent navigation, we'll handle it
      }
    }
    
    // Allow navigation to Stripe checkout and other pages
    return NavigationDecision.navigate;
  }

  Future<void> _createCheckoutSession() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final eventId = args['eventId'] as String;
    final priceTierId = args['priceTierId'] as String;
    final quantity = args['quantity'] as int;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.accessToken;

      if (token == null) {
        setState(() {
          _error = 'Not authenticated. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      // Create checkout session
      final response = await ApiClient.post(
        '/Order/create-checkout-session',
        {
          'eventId': eventId,
          'items': [
            {
              'priceTierId': priceTierId,
              'quantity': quantity,
            }
          ],
        },
        token: token,
      );

      final checkoutUrl = response['url'] as String?;
      final orderId = response['orderId'] as String?;
      final sessionId = response['sessionId'] as String?;
      
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        setState(() {
          _error = 'Failed to create checkout session. Please try again.';
          _isLoading = false;
        });
        return;
      }

      // Store order and session info (for potential future use)
      _orderId = orderId;
      _sessionId = sessionId;

      setState(() {
        _checkoutUrl = checkoutUrl;
        _isLoading = false;
        _isPaymentProcessing = true;
      });

      // Load checkout URL in WebView
      if (_controller != null) {
        await _controller!.loadRequest(Uri.parse(checkoutUrl));
      } else {
        setState(() {
          _error = 'WebView not initialized. Please try again.';
          _isLoading = false;
        });
      }

    } catch (e) {
      String errorMessage = 'An error occurred while creating checkout session.';
      
      // Try to extract user-friendly error message
      if (e.toString().contains('message')) {
        try {
          // If error is a JSON string, try to parse it
          final errorStr = e.toString();
          if (errorStr.contains('{')) {
            final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(errorStr);
            if (jsonMatch != null) {
              final errorData = jsonDecode(jsonMatch.group(0)!);
              if (errorData is Map && errorData.containsKey('message')) {
                errorMessage = errorData['message'] as String;
              } else if (errorData is Map && errorData.containsKey('detail')) {
                errorMessage = errorData['detail'] as String;
              }
            }
          }
        } catch (_) {
          // If parsing fails, use the original error message
          if (e.toString().contains('SocketException') || 
              e.toString().contains('Failed host lookup')) {
            errorMessage = 'Unable to connect to server. Please check your internet connection.';
          } else {
            errorMessage = e.toString().replaceAll('Exception: ', '');
          }
        }
      } else if (e.toString().contains('SocketException') || 
                 e.toString().contains('Failed host lookup')) {
        errorMessage = 'Unable to connect to server. Please check your internet connection.';
      }
      
      setState(() {
        _error = errorMessage;
        _isLoading = false;
        _isPaymentProcessing = false;
      });
    }
  }

  void _handlePageNavigation(String url) {
    if (!mounted) return;
    
    // Check for success redirect - match backend URL pattern
    if (url.contains('/api/order/success') || url.contains('/order/success')) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final sessionId = uri.queryParameters['session_id'];
        final orderId = uri.queryParameters['order_id'];
        
        if (sessionId != null && orderId != null) {
          _orderId = orderId;
          _sessionId = sessionId;
          _handlePaymentSuccess();
          return;
        }
      }
    }
    
    // Check for cancel redirect - match backend URL pattern
    if (url.contains('/api/order/cancel') || url.contains('/order/cancel')) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final orderId = uri.queryParameters['order_id'];
        if (orderId != null) {
          _orderId = orderId;
          _handlePaymentCancel();
          return;
        }
      }
    }
  }

  void _handlePaymentSuccess() {
    if (!mounted) return;
    
    setState(() {
      _isPaymentProcessing = false;
    });
    
    // Navigate to tickets screen and clear navigation stack
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.tickets,
      (route) => false,
    );
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful! Your tickets are ready.'),
        backgroundColor: AppTheme.success,
        duration: Duration(seconds: 4),
      ),
    );
    
    // Wait a bit for webhook to process, then refresh tickets
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Trigger refresh by navigating again or using a callback
        // The ticket list screen will refresh on didChangeDependencies
      }
    });
  }

  void _handlePaymentCancel() {
    if (!mounted) return;
    
    setState(() {
      _isPaymentProcessing = false;
    });
    
    // Navigate back to event detail
    Navigator.of(context).pop();
    
    // Show cancellation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment was cancelled'),
        backgroundColor: AppTheme.warning,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isPaymentProcessing,
      onPopInvoked: (didPop) {
        if (!didPop && _isPaymentProcessing) {
          _showCancelDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              if (_isPaymentProcessing) {
                _showCancelDialog();
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Preparing checkout...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Checkout Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _error = null;
                      });
                      _createCheckoutSession();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_checkoutUrl == null || _controller == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 64,
              color: AppTheme.warning,
            ),
            const SizedBox(height: 16),
            Text(
              'No checkout URL available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _checkoutUrl = null;
                });
                _createCheckoutSession();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller!),
        if (_isPaymentProcessing)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white.withOpacity(0.9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Processing payment...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel checkout?'),
        content: Text(
          _isPaymentProcessing
              ? 'Payment is in progress. Are you sure you want to cancel?'
              : 'Are you sure you want to cancel the checkout process?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              if (mounted) {
                Navigator.pop(context); // Close checkout screen
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.error,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
