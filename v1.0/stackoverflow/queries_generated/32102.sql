WITH RecursivePostStats AS (
    -- Recursive CTE to get hierarchy of answers for questions
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        1 AS Level
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT ParentId, COUNT(*) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostStats r ON r.PostId = p.ParentId
    WHERE 
        p.PostTypeId = 2  -- Only answers
),
AggregatedStats AS (
    -- Aggregating views and scores by user
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(ps.ViewCount) AS TotalViews,
        SUM(ps.Score) AS TotalScore,
        COUNT(DISTINCT ps.PostId) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        RecursivePostStats ps ON p.Id = ps.PostId
    GROUP BY 
        u.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(a.TotalViews, 0) AS TotalViews,
    COALESCE(a.TotalScore, 0) AS TotalScore,
    a.PostCount,
    CASE 
        WHEN a.PostCount > 0 THEN ROUND(COALESCE(a.TotalScore, 0) * 1.0 / a.PostCount, 2) 
        ELSE 0 
    END AS AverageScorePerPost,
    ROW_NUMBER() OVER (ORDER BY COALESCE(a.TotalScore, 0) DESC) AS Rank
FROM 
    Users u
LEFT JOIN 
    AggregatedStats a ON u.Id = a.UserId
WHERE 
    u.Reputation > 1000  -- Only users with reputation greater than 1000
ORDER BY 
    Rank
FETCH FIRST 10 ROWS ONLY; -- Limiting to top 10 users based on their total scores
