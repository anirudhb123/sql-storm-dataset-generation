WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
), UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
), PostsWithComments AS (
    SELECT 
        rp.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.Id
    GROUP BY 
        rp.Id
)
SELECT 
    ud.DisplayName,
    ud.Reputation,
    ud.BadgeCount,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    pwc.CommentCount,
    pwc.LastCommentDate
FROM 
    UserDetails ud
JOIN 
    RankedPosts rp ON ud.UserId = rp.OwnerUserId
JOIN 
    PostsWithComments pwc ON rp.Id = pwc.PostId
WHERE 
    rp.UserPostRank = 1
ORDER BY 
    ud.Reputation DESC, 
    rp.Score DESC;
