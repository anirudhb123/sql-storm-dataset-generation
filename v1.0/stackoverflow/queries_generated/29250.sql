WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts from the last year
),
EnhancedPostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON rp.PostId = c.PostId
)
SELECT 
    epd.PostId,
    epd.Title,
    epd.Body,
    epd.CreationDate,
    epd.OwnerDisplayName,
    epd.Score,
    epd.ViewCount,
    epd.Tags,
    epd.BadgeCount,
    epd.CommentCount,
    pst.Name AS PostStatus,
    pt.Name AS PostType,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
FROM 
    EnhancedPostDetails epd
LEFT JOIN 
    PostHistory ph ON ph.PostId = epd.PostId
LEFT JOIN 
    PostHistoryTypes pst ON ph.PostHistoryTypeId = pst.Id
LEFT JOIN 
    PostTypes pt ON epd.PostId = pt.Id
LEFT JOIN 
    unnest(string_to_array(epd.Tags, '<>')) AS t(TagName)
GROUP BY 
    epd.PostId, epd.Title, epd.Body, epd.CreationDate, epd.OwnerDisplayName, 
    epd.Score, epd.ViewCount, epd.BadgeCount, epd.CommentCount, pst.Name, pt.Name
ORDER BY 
    epd.Score DESC, epd.ViewCount DESC;
