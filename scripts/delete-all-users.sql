-- Delete all users and related data from SQLite database
-- This script deletes all users, their roles, claims, tokens, and password reset tokens

-- Delete password reset tokens first (foreign key constraint)
DELETE FROM PasswordResetTokens;

-- Delete user roles (AspNetUserRoles)
DELETE FROM AspNetUserRoles;

-- Delete user claims (AspNetUserClaims)
DELETE FROM AspNetUserClaims;

-- Delete user logins (AspNetUserLogins)
DELETE FROM AspNetUserLogins;

-- Delete user tokens (AspNetUserTokens)
DELETE FROM AspNetUserTokens;

-- Finally, delete all users (AspNetUsers)
DELETE FROM AspNetUsers;

-- Note: Orders, Tickets, and other data linked to users will remain
-- but will have orphaned UserId references

