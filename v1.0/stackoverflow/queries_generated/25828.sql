WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tagName ON TRUE
    LEFT JOIN 
        Tags t ON tagName = t.TagName
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),

PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        CASE 
            WHEN rp.OwnerPostRank = 1 THEN 'Latest Post'
            WHEN rp.OwnerPostRank > 1 THEN 'Earlier Post'
            ELSE 'No Posts'
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.Score, rp.ViewCount, rp.Tags, rp.OwnerPostRank
)

SELECT 
    pm.PostId,
    pm.Title,
    pm.OwnerDisplayName,
    pm.CreationDate,
    pm.Score,
    pm.ViewCount,
    pm.Tags,
    pm.CommentCount,
    pm.UpVotes,
    pm.DownVotes,
    pm.PostStatus,
    CURRENT_TIMESTAMP - pm.CreationDate AS TimeSinceCreation
FROM 
    PostMetrics pm
WHERE 
    pm.Score > 0
ORDER BY 
    pm.ViewCount DESC, pm.Score DESC
LIMIT 10;
