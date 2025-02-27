WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_arr ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag_arr
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName
),
PostRankings AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY CommentCount DESC) AS CommentRank,
        RANK() OVER (ORDER BY BadgeCount DESC) AS BadgeRank
    FROM 
        RankedPosts
)
SELECT 
    PostId,
    Title,
    Body,
    CreationDate,
    ViewCount,
    OwnerDisplayName,
    CommentCount,
    BadgeCount,
    Tags,
    ViewRank,
    CommentRank,
    BadgeRank
FROM 
    PostRankings
WHERE 
    ViewRank <= 10 OR CommentRank <= 10 OR BadgeRank <= 10
ORDER BY 
    ViewRank, CommentRank, BadgeRank;
