WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        ARRAY_AGG(t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND
        p.Score > 0
    GROUP BY 
        p.Id, pt.Name, p.Title, p.Body, p.CreationDate, p.ViewCount
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Tags,
    COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    STRING_AGG(DISTINCT CASE WHEN b.Class = 1 THEN b.Name END, ', ') AS GoldBadges,
    STRING_AGG(DISTINCT CASE WHEN b.Class = 2 THEN b.Name END, ', ') AS SilverBadges,
    STRING_AGG(DISTINCT CASE WHEN b.Class = 3 THEN b.Name END, ', ') AS BronzeBadges,
    STRING_AGG(DISTINCT IFNULL(ph.Comment, ''), '; ') AS HistoryComments
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id 
LEFT JOIN 
    Comments c ON rp.PostId = c.PostId
LEFT JOIN 
    Votes v ON rp.PostId = v.PostId AND v.VoteTypeId = 8 -- BountyStart
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId
WHERE 
    rp.Rank <= 3 -- Get top 3 ranked posts within each post type
GROUP BY 
    rp.PostId, rp.Title, rp.ViewCount, u.DisplayName
ORDER BY 
    rp.ViewCount DESC;
