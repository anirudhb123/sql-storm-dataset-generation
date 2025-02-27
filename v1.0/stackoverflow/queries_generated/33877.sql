WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions as starting points

    UNION ALL 

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.CreationDate,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostDetails AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        MAX(ph.CreationDate) AS LastModified,
        ph.PostHistoryTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter to posts created in the last year
    GROUP BY 
        p.Id
),
PostScoreRanking AS (
    SELECT 
        pd.*,
        RANK() OVER (ORDER BY pd.Score DESC, pd.ViewCount DESC) AS ScoreRank
    FROM 
        PostDetails pd
    WHERE 
        pd.CommentCount > 0  -- Only posts with comments
)

SELECT 
    pth.PostId,
    pth.Title,
    pth.Level,
    pd.OwnerUserId,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    ps.ScoreRank
FROM 
    RecursivePostHierarchy pth
JOIN 
    PostScoreRanking pd ON pth.PostId = pd.Id
JOIN 
    Users u ON pd.OwnerUserId = u.Id
WHERE 
    u.Reputation > 500  -- Filter for users with reputation higher than 500
    AND pd.ScoreRank <= 10  -- Limit to top 10 posts based on score
ORDER BY 
    pth.Level, pd.UpVoteCount DESC;
