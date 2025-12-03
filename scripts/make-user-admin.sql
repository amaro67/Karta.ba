-- Make a user admin by email
-- Usage: sqlcmd -S localhost,1433 -d KartaDb -U sa -P YourPassword -i make-user-admin.sql
-- Or connect via SSMS or Azure Data Studio and run this script

-- Example: Make admin@test.com an admin
-- Uncomment and modify the email below:
-- INSERT INTO AspNetUserRoles (UserId, RoleId) 
-- SELECT u.Id, r.Id 
-- FROM AspNetUsers u, AspNetRoles r 
-- WHERE u.Email = 'admin@test.com' AND r.Name = 'Admin';

-- Or make the first registered user an admin:
INSERT INTO AspNetUserRoles (UserId, RoleId) 
SELECT u.Id, r.Id 
FROM AspNetUsers u, AspNetRoles r 
WHERE r.Name = 'Admin'
AND u.Id = (SELECT Id FROM AspNetUsers ORDER BY CreatedAt LIMIT 1)
AND NOT EXISTS (
    SELECT 1 FROM AspNetUserRoles ur 
    WHERE ur.UserId = u.Id AND ur.RoleId = r.Id
);

