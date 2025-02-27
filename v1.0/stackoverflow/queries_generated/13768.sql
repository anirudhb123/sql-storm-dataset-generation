-- Performance benchmarking query to analyze the performance of posts created by users with high reputation
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.UpVotes) AS TotalUpVotes,
        SUM(p.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000 -- focusing on users with high reputation
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    AverageScore,
    TotalViews,
    TotalUpVotes,
    TotalDownVotes,
    (TotalUpVotes - TotalDownVotes) AS NetVotes -- Calculating net votes for posts
FROM 
    UserPostStats
ORDER BY 
    PostCount DESC; -- Ordering by the number of posts created
