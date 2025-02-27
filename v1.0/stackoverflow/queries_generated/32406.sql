WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.ViewCount,
        p.Score,
        0 AS Level,
        CAST(p.Title AS VARCHAR(300)) AS Path
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL -- Starting with top-level posts (questions)

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.ViewCount,
        p.Score,
        rp.Level + 1,
        CAST(rp.Path || ' -> ' || p.Title AS VARCHAR(300))
    FROM 
        Posts p
    INNER JOIN 
        RecursivePosts rp ON p.ParentId = rp.Id
),
RankedPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerUserId,
        rp.Score,
        rp.ViewCount,
        rp.Level,
        RANK() OVER (PARTITION BY rp.Level ORDER BY rp.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (PARTITION BY rp.OwnerUserId ORDER BY rp.CreationDate DESC) AS UserPostRank
    FROM 
        RecursivePosts rp
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (24, 52) THEN 1 END) AS TotalEdits
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    u.DisplayName AS OwnerName,
    ph.CloseVotes,
    ph.ReopenVotes,
    ph.TotalEdits,
    rp.Score AS PostScore,
    rp.ViewCount,
    CASE 
        WHEN rp.Score > 100 THEN 'High Score'
        WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    RankedPosts rp
INNER JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    PostHistoryAggregates ph ON rp.Id = ph.PostId
LEFT JOIN 
    LATERAL (
        SELECT 
            string_to_array(p.Tags, ' ') AS TagName
        FROM 
            Posts p
        WHERE 
            p.Id = rp.Id
    ) t ON true
LEFT JOIN 
    Votes v ON rp.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Upvotes and downvotes
WHERE 
    rp.ScoreRank <= 5 -- Top 5 scores per level
GROUP BY 
    rp.Id, u.DisplayName, ph.CloseVotes, ph.ReopenVotes, ph.TotalEdits, rp.Score, rp.ViewCount
ORDER BY 
    rp.Level, rp.Score DESC;
