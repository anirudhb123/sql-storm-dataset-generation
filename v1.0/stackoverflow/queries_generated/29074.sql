WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_array ON TRUE
    LEFT JOIN 
        Tags t ON tag_array.value = t.TagName
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(ph.Id) AS HistoryCount,
        MAX(p.LastActivityDate) AS LastActivity
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
EnrichedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Author,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        pa.CommentCount,
        pa.HistoryCount,
        pa.LastActivity
    FROM 
        RankedPosts rp
    JOIN 
        PostActivity pa ON rp.PostId = pa.PostId
)
SELECT 
    ep.PostId,
    ep.Title,
    ep.Author,
    ep.CreationDate,
    ep.Score,
    ep.ViewCount,
    ep.CommentCount,
    ep.HistoryCount,
    ep.LastActivity,
    ep.Tags,
    CASE 
        WHEN ep.Score > 100 THEN 'High Score'
        WHEN ep.Score BETWEEN 50 AND 100 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    CASE 
        WHEN ep.CreationDate < NOW() - INTERVAL '1 year' THEN 'Old Post'
        ELSE 'Recent Post'
    END AS PostAge
FROM 
    EnrichedPosts ep
ORDER BY 
    ep.Score DESC, ep.CommentCount DESC, ep.ViewCount DESC
LIMIT 50;
