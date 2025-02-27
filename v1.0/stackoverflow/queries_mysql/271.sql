
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.UserId END) AS UpvoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.UserId END) AS DownvoteCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01 12:34:56', INTERVAL 1 YEAR)
    GROUP BY 
        p.Id, p.Title
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpvoteCount,
        ps.DownvoteCount,
        ps.CloseCount,
        @rank := @rank + 1 AS Rank
    FROM 
        PostStats ps,
        (SELECT @rank := 0) r
    WHERE 
        ps.UpvoteCount - ps.DownvoteCount > 0
    ORDER BY 
        ps.UpvoteCount DESC
)
SELECT 
    t.Title,
    t.CommentCount,
    t.UpvoteCount,
    t.DownvoteCount,
    t.CloseCount,
    u.DisplayName,
    COALESCE(ub.GoldCount, 0) AS GoldBadges,
    COALESCE(ub.SilverCount, 0) AS SilverBadges,
    COALESCE(ub.BronzeCount, 0) AS BronzeBadges
FROM 
    TopPosts t
JOIN 
    Posts p ON t.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadgeCounts ub ON ub.UserId = u.Id
WHERE 
    t.Rank <= 10
ORDER BY 
    t.UpvoteCount DESC;
