
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(p.OwnerDisplayName, 'Community') AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditHistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(p.Tags, '><')) AS t ON TRUE
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerDisplayName
),
PostRankings AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        rp.CommentCount,
        rp.EditHistoryCount,
        RANK() OVER (ORDER BY rp.Score DESC, rp.ViewCount DESC, rp.CreationDate ASC) AS PostRank
    FROM 
        RankedPosts rp
)
SELECT 
    pr.Id,
    pr.Title,
    pr.OwnerDisplayName,
    pr.CreationDate,
    pr.Score,
    pr.ViewCount,
    pr.Tags,
    pr.CommentCount,
    pr.EditHistoryCount,
    pr.PostRank
FROM 
    PostRankings pr
WHERE 
    pr.PostRank <= 10
ORDER BY 
    pr.PostRank;
