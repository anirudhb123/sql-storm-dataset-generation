-- Retrieve the top 10 users by reputation along with their display name and creation date
SELECT 
    Id, 
    DisplayName, 
    Reputation, 
    CreationDate 
FROM 
    Users 
ORDER BY 
    Reputation DESC 
LIMIT 10;
