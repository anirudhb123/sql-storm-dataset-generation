-- Performance Benchmarking Query Example
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(p.DownVotes, 0)) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 0 -- Only consider users with positive reputation
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        TotalScore, 
        TotalViews, 
        TotalUpVotes, 
        TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserPostStats
)
SELECT 
    UserId, 
    DisplayName, 
    PostCount, 
    TotalScore, 
    TotalViews, 
    TotalUpVotes, 
    TotalDownVotes
FROM 
    TopUsers
WHERE 
    Rank <= 10; -- Get top 10 users by total score

