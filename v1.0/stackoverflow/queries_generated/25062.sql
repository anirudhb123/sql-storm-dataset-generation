WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag_name ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.RankByScore <= 3 THEN 'Top 3'
            ELSE 'Others'
        END AS PostRankCategory
    FROM 
        RankedPosts rp
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    up.UserId,
    up.DisplayName,
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.PostRankCategory,
    up.TotalUpvotes,
    up.TotalDownvotes,
    up.BadgeCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    TopPosts tp
JOIN 
    Users up ON tp.OwnerUserId = up.Id
LEFT JOIN 
    unnest(tp.TagsList) AS t(TagName) ON true
GROUP BY 
    up.UserId, up.DisplayName, tp.PostId, tp.Title, tp.Body, tp.CreationDate, tp.Score, tp.ViewCount, tp.CommentCount, tp.PostRankCategory, up.TotalUpvotes, up.TotalDownvotes, up.BadgeCount
ORDER BY 
    tp.PostRankCategory, tp.Score DESC, up.DisplayName;
