-- Performance benchmarking query for the StackOverflow schema

-- Measure the average time taken to query users with more than a specific number of reputation points
-- and the number of badges they have earned.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(b.Id) AS BadgeCount,
    AVG(DATEDIFF(MINUTE, u.CreationDate, GETDATE())) AS AverageAccountAgeInMinutes
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.Reputation > 100
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;

This query benchmarks the performance of aggregating user data based on reputation and the count of badges. It uses a left join between the Users and Badges tables, along with a count aggregation to derive insights about the users. Adjust the `WHERE` clause to change the reputation threshold as needed.
