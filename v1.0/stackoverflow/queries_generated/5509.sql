WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Author,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY COUNT(c.Id) DESC) AS RankByComments
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND  -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Posts from the last year
    GROUP BY 
        p.Id, u.DisplayName
), UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Author,
    r.ViewCount,
    r.Score,
    r.CommentCount,
    r.RankByComments,
    ub.BadgeNames,
    ub.BadgeCount
FROM 
    RankedPosts r
LEFT JOIN 
    UserBadges ub ON r.Author = ub.UserId
WHERE 
    r.RankByComments <= 10  -- Only top 10 posts by comments
ORDER BY 
    r.RankByComments;
