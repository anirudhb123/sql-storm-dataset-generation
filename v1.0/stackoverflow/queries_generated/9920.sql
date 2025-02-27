WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreatedAt,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreatedAt
    ORDER BY 
        UpVotes DESC
    LIMIT 10
)
SELECT 
    ubc.DisplayName,
    ubc.BadgeCount,
    tp.Title AS TopPostTitle,
    tp.CommentCount AS PostComments,
    tp.UpVotes,
    tp.DownVotes,
    tp.CreationDate
FROM 
    UserBadgeCounts ubc
JOIN 
    TopPosts tp ON ubc.UserId = tp.OwnerUserId
ORDER BY 
    ubc.BadgeCount DESC, tp.UpVotes DESC;
