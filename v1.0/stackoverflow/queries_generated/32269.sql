WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting from Questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
    WHERE 
        p.PostTypeId = 2  -- Only consider Answers
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 2  -- Join with Answers
    LEFT JOIN 
        Comments c ON p.Id = c.PostId  -- Join Comments on Answers
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.PostId IN (SELECT PostId FROM PostHierarchy) -- Votes on Questions and their answers
    GROUP BY 
        u.Id
),
PostMetrics AS (
    SELECT 
        ph.PostId,
        ph.Title,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        ph.Level,
        COUNT(c.Id) AS TotalComments,
        AVG(p.Score) AS AvgScore,
        MAX(p.CreationDate) AS LastActivityDate
    FROM 
        PostHierarchy ph
    LEFT JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        ph.PostId, ph.Title, OwnerDisplayName, ph.Level
),
FinalStats AS (
    SELECT 
        um.UserId,
        um.DisplayName,
        pm.TotalComments,
        pm.AvgScore,
        pm.LastActivityDate,
        um.AnswerCount,
        um.CommentCount,
        um.TotalBounty,
        RANK() OVER (ORDER BY um.TotalBounty DESC) AS BountyRank,
        DENSE_RANK() OVER (PARTITION BY pm.Level ORDER BY pm.AvgScore DESC) AS ScoreRank
    FROM 
        UserStatistics um
    JOIN 
        PostMetrics pm ON um.UserId = pm.OwnerDisplayName
)
SELECT 
    fs.UserId,
    fs.DisplayName,
    fs.TotalComments,
    fs.AvgScore,
    fs.LastActivityDate,
    fs.AnswerCount,
    fs.CommentCount,
    fs.TotalBounty,
    fs.BountyRank,
    fs.ScoreRank
FROM 
    FinalStats fs
WHERE 
    fs.TotalComments > 5 AND 
    fs.AvgScore IS NOT NULL
ORDER BY 
    fs.BountyRank, fs.ScoreRank;
