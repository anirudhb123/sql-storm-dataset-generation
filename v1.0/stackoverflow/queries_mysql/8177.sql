
WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.Reputation > 100
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostMeta AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM Posts p
    LEFT JOIN (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', n.n), '<>', -1)) AS Tag
                FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
                      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
                      UNION ALL SELECT 9 UNION ALL SELECT 10) n
                WHERE n.n <= 1 + (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '<>', '')))) 
               ) AS tag ON true
    JOIN Tags t ON t.TagName = tag.Tag
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT
        pm.PostId,
        pm.Title,
        pm.CreationDate,
        pm.Score,
        pm.ViewCount,
        pm.Tags,
        @row_number := @row_number + 1 AS Rank
    FROM PostMeta pm, (SELECT @row_number := 0) AS r
    WHERE pm.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY pm.Score DESC, pm.ViewCount DESC
)
SELECT
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.AnswerCount,
    us.QuestionCount,
    us.CommentCount,
    us.BadgeCount,
    us.VoteCount,
    tp.Title AS TopPostTitle,
    tp.Score AS TopPostScore,
    tp.ViewCount AS TopPostViewCount,
    tp.Tags AS TopPostTags
FROM UserStats us
LEFT JOIN TopPosts tp ON us.UserId = tp.PostId
WHERE tp.Rank <= 5
ORDER BY us.Reputation DESC, us.VoteCount DESC;
