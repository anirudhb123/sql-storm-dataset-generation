WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        RANK() OVER (ORDER BY ps.Score DESC) AS PostRank
    FROM PostStats ps
)
SELECT 
    um.DisplayName,
    um.PostCount,
    um.CommentCount,
    um.UpVoteCount,
    um.DownVoteCount,
    um.GoldBadges,
    um.SilverBadges,
    um.BronzeBadges,
    tp.Title AS TopPostTitle,
    tp.Score AS TopPostScore,
    tp.ViewCount AS TopPostViewCount,
    tp.CommentCount AS TopPostCommentCount
FROM UserMetrics um
LEFT JOIN TopPosts tp ON um.UserId = (SELECT OWNERUSERID FROM posts WHERE ID = tp.PostId)
WHERE um.PostCount > 10
ORDER BY um.UpVoteCount DESC, um.Reputation DESC;
