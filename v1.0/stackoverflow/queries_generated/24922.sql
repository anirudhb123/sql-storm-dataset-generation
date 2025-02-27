WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),

TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        rp.CommentCount,
        rp.TagList
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 2
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    trp.PostId,
    trp.Title,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    trp.CommentCount,
    trp.TagList,
    ub.UserId,
    ub.BadgeCount,
    CASE 
        WHEN ub.HighestBadgeClass = 1 THEN 'Gold'
        WHEN ub.HighestBadgeClass = 2 THEN 'Silver'
        WHEN ub.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'No Badge'
    END AS BadgeLevel,
    CASE 
        WHEN trp.CommentCount IS NULL OR trp.CommentCount = 0 THEN 'No Comments'
        WHEN trp.CommentCount >= 5 THEN 'Many Comments'
        ELSE 'Few Comments'
    END AS CommentStatus
FROM 
    TopRankedPosts trp
LEFT JOIN 
    UserBadges ub ON trp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ub.UserId)
WHERE 
    trp.Score > COALESCE((SELECT AVG(Score) FROM Posts WHERE CreationDate >= NOW() - INTERVAL '1 year'), 0)
ORDER BY 
    trp.Score DESC, trp.CreationDate ASC;

This query is designed to analyze the performance of posts made in the last year, ranking them by score and counting associated comments while also retrieving badge information for their authors. It utilizes CTEs for better structure and clarity and implements various SQL constructs like outer joins, window functions, and conditional logic to derive useful insights.
