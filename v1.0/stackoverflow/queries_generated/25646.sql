WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS RankByViewCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),

RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY 
        c.PostId
),

PopularTags AS (
    SELECT 
        t.TagName,
        SUM(pls.PostId IS NOT NULL) AS LinksCount
    FROM 
        Tags t
    LEFT JOIN 
        PostLinks pls ON t.Id = pls.RelatedPostId
    GROUP BY 
        t.TagName
    ORDER BY 
        LinksCount DESC
    LIMIT 5
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerName,
    rp.PostType,
    rc.CommentCount,
    rc.LastCommentDate,
    pg.TagName AS PopularTag
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentComments rc ON rp.PostId = rc.PostId
CROSS JOIN 
    PopularTags pg
WHERE 
    rp.RankByViewCount <= 10 -- Filter top 10 posts by views
ORDER BY 
    rp.PostId;
