WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Base case: Start with Questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.CreationDate,
        a.ViewCount,
        a.Score,
        a.AcceptedAnswerId,
        rp.Level + 1 AS Level
    FROM 
        Posts a
    JOIN 
        RecursivePostCTE rp ON a.ParentId = rp.PostId
    WHERE 
        a.PostTypeId = 2  -- Recursive case: Find Answers to Questions
),

RankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Level,
        RANK() OVER (PARTITION BY rp.Level ORDER BY rp.Score DESC) AS ScoreRank
    FROM 
        RecursivePostCTE rp
    WHERE 
        rp.Score IS NOT NULL
),

PostDetails AS (
    SELECT 
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.Level,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(v.DownVoteCount, 0) AS DownVoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON rp.PostId = v.PostId
)

SELECT 
    pd.Title,
    pd.ViewCount,
    pd.CreationDate,
    pd.Level,
    pd.UpVoteCount,
    pd.DownVoteCount
FROM 
    PostDetails pd
WHERE 
    pd.Level = (SELECT MAX(Level) FROM PostDetails)  -- Get all top-level answers
    AND pd.UpVoteCount > 5  -- Filter for popular answers
ORDER BY 
    pd.ViewCount DESC  -- Order by most viewed
OPTION (RECOMPILE);
