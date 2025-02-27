WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        MAX(CASE WHEN b.UserId IS NOT NULL THEN 1 ELSE 0 END) AS HasBadges
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name, u.DisplayName
)
SELECT 
    rp.*, 
    COALESCE(ARRAY_AGG(DISTINCT t.TagName) FILTER (WHERE t.TagName IS NOT NULL), '{}') AS Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    LATERAL (
        SELECT DISTINCT 
            SUBSTRING(tag, 2, LENGTH(tag)-2) AS TagName
        FROM 
            unnest(string_to_array(rp.Tags, '><')) AS tag
    ) t ON true
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC
LIMIT 100;
