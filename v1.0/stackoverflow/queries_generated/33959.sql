WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId  -- Join to find Answers
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart votes
    WHERE 
        u.Reputation > 100  -- Considering users with high reputation
    GROUP BY 
        u.Id
),

PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        v.VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId) v ON p.Id = v.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Filter for Questions only
),

FinalBenchmark AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ud.DisplayName,
        ud.Reputation,
        ud.PostCount,
        pd.CommentCount,
        pd.Score,
        pd.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ud.UserId ORDER BY pd.Score DESC) AS UserRank,
        RANK() OVER (ORDER BY pd.Score DESC) AS PostRank
    FROM 
        RecursivePostHierarchy ph
    JOIN 
        UserReputation ud ON ph.OwnerUserId = ud.UserId
    JOIN 
        PostDetails pd ON ph.PostId = pd.PostId
)

SELECT 
    fb.*,
    CONCAT('Post Title: ', fb.Title, ' | Owner: ', fb.DisplayName, ' | Score: ', fb.Score) AS PostInfo,
    CASE
        WHEN fb.Score > 10 THEN 'High Scoring Post'
        WHEN fb.Score BETWEEN 1 AND 10 THEN 'Moderate Scoring Post'
        ELSE 'Low Scoring Post'
    END AS ScoreCategory
FROM 
    FinalBenchmark fb 
WHERE 
    fb.UserRank = 1  -- Only select the top-ranked post for each user
ORDER BY 
    fb.PostRank;
