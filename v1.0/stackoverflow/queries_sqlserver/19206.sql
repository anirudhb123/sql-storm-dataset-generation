
SELECT TOP 10 
    Id, 
    DisplayName, 
    Reputation, 
    CreationDate 
FROM 
    Users 
ORDER BY 
    Reputation DESC;
