
WITH RankedPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.CreationDate, 
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
           @row_number := IF(@prev_post_type = p.PostTypeId, @row_number + 1, 1) AS Rank,
           @prev_post_type := p.PostTypeId
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_post_type := NULL) AS r
    WHERE p.CreationDate > (NOW() - INTERVAL 1 YEAR)
    GROUP BY p.Id, p.Title, p.CreationDate
),
TopRankedPosts AS (
    SELECT PostId, Title, CreationDate, CommentCount, Upvotes, Downvotes
    FROM RankedPosts
    WHERE Rank <= 5
)
SELECT trp.*, 
       u.DisplayName AS UserDisplayName, 
       COALESCE(AVG(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadgeCount,
       COALESCE(AVG(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadgeCount,
       COALESCE(AVG(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadgeCount
FROM TopRankedPosts trp
LEFT JOIN Users u ON trp.PostId = u.Id
LEFT JOIN Badges b ON u.Id = b.UserId
GROUP BY trp.PostId, trp.Title, trp.CreationDate, trp.CommentCount, trp.Upvotes, trp.Downvotes, u.DisplayName
ORDER BY trp.Upvotes DESC, trp.CommentCount DESC;
