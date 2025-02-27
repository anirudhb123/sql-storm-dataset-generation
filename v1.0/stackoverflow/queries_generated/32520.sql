WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
)
, PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(pc.Count, 0) AS CommentCount,
        COALESCE(accepted.Title, 'N/A') AS AcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
            PostId, COUNT(*) AS Count 
         FROM 
            Comments 
         GROUP BY 
            PostId) pc ON p.Id = pc.PostId
    LEFT JOIN 
        Posts accepted ON p.AcceptedAnswerId = accepted.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
),
RankingDetails AS (
    SELECT 
        pd.*,
        RANK() OVER (ORDER BY pd.Score DESC) AS ScoreRank,
        DENSE_RANK() OVER (PARTITION BY pd.Owner ORDER BY pd.ViewCount DESC) AS ViewRank
    FROM 
        PostDetails pd
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Owner,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.AcceptedAnswer,
    rd.ScoreRank,
    rd.ViewRank
FROM 
    RankingDetails rd
JOIN 
    PostHierarchy ph ON rd.PostId = ph.PostId
WHERE 
    ph.Level <= 2  -- Display hierarchy up to 2 levels deep
ORDER BY 
    rd.ScoreRank, rd.ViewRank;
