WITH RecursiveCTE AS (
    SELECT 
        Id,
        Title,
        ViewCount,
        Score,
        CreationDate,
        OwnerUserId,
        ParentId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Get top-level questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursiveCTE r ON p.ParentId = r.Id -- Join with the CTE to get answers
    WHERE 
        p.PostTypeId = 2 
),
AggData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        ROW_NUMBER() OVER (PARTITION BY v.PostId ORDER BY v.CreationDate DESC) AS VoteRank
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '30 days'  -- Votes in the last 30 days
)

SELECT 
    u.DisplayName,
    COALESCE(a.TotalScore, 0) AS TotalScore,
    COALESCE(a.TotalPosts, 0) AS TotalPosts,
    COALESCE(a.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(a.TotalAnswers, 0) AS TotalAnswers,
    p.Title AS RecentPostTitle,
    COUNT(rv.UserId) AS RecentVoteCount,
    ROUND(AVG(Score) OVER (PARTITION BY u.Id), 2) AS AverageScore,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypes
FROM 
    Users u
LEFT JOIN 
    AggData a ON u.Id = a.UserId
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    RecentVotes rv ON p.Id = rv.PostId AND rv.VoteRank = 1
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    u.Reputation BETWEEN 100 AND 10000
GROUP BY 
    u.Id, u.DisplayName, p.Title
ORDER BY 
    TotalScore DESC
LIMIT 10;
