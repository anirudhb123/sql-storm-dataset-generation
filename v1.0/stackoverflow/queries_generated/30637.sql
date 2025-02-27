WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Start with top-level Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        Level + 1 -- Increment level for answers
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON r.PostId = p.ParentId
    WHERE 
        p.PostTypeId = 2 -- Only include Answers
),
UserRankedPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        RANK() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS Rank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostClosureDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        pt.Name AS PostHistoryType,
        ph.Comment
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
        AND ph.PostHistoryTypeId IN (10, 11) -- Closures and Reopenings
),
UserPostDetails AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        pcd.PostHistoryType,
        pcd.Comment,
        u.DisplayName AS Owner
    FROM 
        RecursivePostCTE r
    LEFT JOIN 
        PostClosureDetails pcd ON r.PostId = pcd.PostId
    LEFT JOIN 
        Users u ON r.OwnerUserId = u.Id
)
SELECT 
    upd.Owner,
    COUNT(DISTINCT upd.PostId) AS TotalPosts,
    SUM(upd.Score) AS TotalScore,
    MAX(upd.CreationDate) AS LastActiveDate,
    STRING_AGG(upd.Title, ', ') AS Titles,
    CASE 
        WHEN COUNT(DISTINCT upd.PostId) > 5 THEN 'High Activity'
        WHEN COUNT(DISTINCT upd.PostId) BETWEEN 1 AND 5 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel
FROM 
    UserPostDetails upd
WHERE 
    upd.Owner IS NOT NULL
GROUP BY 
    upd.Owner
HAVING 
    SUM(upd.Score) > 50
ORDER BY 
    TotalScore DESC;

-- This query benchmarks performance through multiple techniques such as:
-- Recursive CTEs to fetch posts and answers, subqueries for user and post details,
-- window functions to rank users based on post activity,
-- JOINs to combine relevant data, and conditional aggregates to classify activity levels.
