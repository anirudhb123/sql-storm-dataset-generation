WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        Rank,
        CommentCount,
        UpVoteCount
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 5
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        COUNT(p.Id) AS PostsCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    pa.UserId,
    a.DisplayName,
    COUNT(DISTINCT tp.PostId) AS TopPostCount,
    SUM(CASE WHEN tp.CommentCount > 0 THEN 1 ELSE 0 END) AS CommentedTopPostsCount,
    SUM(CASE WHEN tp.UpVoteCount > 10 THEN 1 ELSE 0 END) AS PopularTopPostsCount,
    SUM(u.PostsCount) AS TotalUserPosts,
    (SELECT COUNT(*) FROM Votes v WHERE v.UserId = pa.UserId AND v.VoteTypeId = 2) AS UpVoteGiven
FROM 
    UserActivity ua
JOIN 
    (SELECT DISTINCT PostId, OwnerUserId FROM TopPosts) AS tp ON tp.OwnerUserId = ua.UserId
JOIN 
    Users a ON tp.OwnerUserId = a.Id
LEFT JOIN 
    Posts p ON ua.UserId = p.OwnerUserId
GROUP BY 
    pa.UserId, a.DisplayName
HAVING 
    SUM(CASE WHEN tp.CommentCount > 0 THEN 1 ELSE 0 END) > 0
ORDER BY 
    TopPostCount DESC, TotalUserPosts DESC;

