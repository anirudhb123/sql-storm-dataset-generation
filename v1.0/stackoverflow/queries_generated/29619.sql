WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS RankWithinTag
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate > NOW() - INTERVAL '30 days' -- Posts created in the last 30 days
    GROUP BY 
        p.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.RankWithinTag <= 3 THEN 'Top'
            WHEN rp.RankWithinTag <= 10 THEN 'Medium'
            ELSE 'Low' 
        END AS PopularityTier
    FROM 
        RankedPosts rp
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.PopularityTier,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    PostStatistics ps
JOIN 
    STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS splitTags ON true -- Assuming tags are stored using '>' and '<'
JOIN 
    Tags t ON t.TagName = TRIM(splitTags) -- Join with Tags table
GROUP BY 
    ps.PostId, ps.Title, ps.OwnerDisplayName, ps.Score, ps.ViewCount, 
    ps.CommentCount, ps.UpVoteCount, ps.DownVoteCount, ps.PopularityTier
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
