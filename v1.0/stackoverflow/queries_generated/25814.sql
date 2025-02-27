WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.Score
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.Tags,
    r.CreationDate,
    r.Score,
    r.CommentCount,
    u.DisplayName AS UserName,
    b.BadgeCount,
    b.BadgeNames
FROM 
    RankedPosts r
JOIN 
    Users u ON u.Id = r.OwnerUserId
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
WHERE 
    r.Rank <= 10 -- Top 10 ranked questions
ORDER BY 
    r.Score DESC, 
    r.CreationDate DESC;
