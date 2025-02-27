
SELECT COUNT(*) AS TotalUsers
FROM Users
GROUP BY UserId; -- Assuming UserId is the primary key or unique identifier of the Users table
