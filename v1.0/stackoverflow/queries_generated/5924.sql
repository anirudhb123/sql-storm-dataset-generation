WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        MAX(v.CreationDate) AS LastVoteDate
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    COALESCE(rv.VoteCount, 0) AS VoteCount,
    COALESCE(rv.LastVoteDate, 'Never') AS LastVoteDate,
    COALESCE(ph.EditCount, 0) AS EditCount,
    COALESCE(ph.LastEditDate, 'Never') AS LastEditDate
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
LEFT JOIN 
    PostHistoryAggregated ph ON rp.PostId = ph.PostId
WHERE 
    rp.PostRank = 1 -- Only latest post per user
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
