
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (2, 4) THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT ph.PostId) AS PostHistoryCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS PostClosedCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ',') AS Tags
    FROM 
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN PostHistory ph ON ph.UserId = u.Id
    LEFT JOIN Posts p ON ph.PostId = p.Id
    LEFT JOIN (
        SELECT p.Id AS PostId, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1) AS TagName
        FROM Posts p
        INNER JOIN (
            SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
            UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
            UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15
            UNION SELECT 16 UNION SELECT 17 UNION SELECT 18 UNION SELECT 19 UNION SELECT 20
        ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
    ) AS t ON t.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),

PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        (SELECT 
            COUNT(c.Id) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS CommentCount,
        @rownum := @rownum + 1 AS RowNum
    FROM 
        Posts p, (SELECT @rownum := 0) AS r
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY p.CreationDate DESC
),

QualifiedUsers AS (
    SELECT 
        ua.UserId, 
        ua.DisplayName, 
        ua.VoteCount,
        ua.Upvotes,
        ua.Downvotes,
        ua.PostHistoryCount,
        ua.PostClosedCount,
        ua.Tags,
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount
    FROM 
        UserActivity ua
    INNER JOIN PostStatistics ps ON ua.UserId = (
        SELECT 
            p.OwnerUserId 
        FROM 
            Posts p 
        WHERE 
            p.Id = ps.PostId) 
    WHERE 
        ua.Upvotes > ua.Downvotes
)

SELECT 
    q.UserId,
    q.DisplayName,
    q.Tags,
    p.PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    CASE 
        WHEN p.Score > 100 THEN 'High Score Post'
        WHEN p.Score BETWEEN 50 AND 100 THEN 'Medium Score Post'
        ELSE 'Low Score Post'
    END AS ScoreCategory,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Badges b WHERE b.UserId = q.UserId AND b.Class = 1) THEN 'Gold Badge Holder'
        WHEN EXISTS (SELECT 1 FROM Badges b WHERE b.UserId = q.UserId AND b.Class = 2) THEN 'Silver Badge Holder'
        WHEN EXISTS (SELECT 1 FROM Badges b WHERE b.UserId = q.UserId AND b.Class = 3) THEN 'Bronze Badge Holder'
        ELSE 'No Badges'
    END AS BadgeStatus
FROM 
    QualifiedUsers q
JOIN 
    PostStatistics p ON q.PostId = p.PostId
WHERE 
    q.PostClosedCount = 0
ORDER BY 
    p.ViewCount DESC, q.Upvotes DESC
LIMIT 50;
