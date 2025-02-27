
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT b.Name SEPARATOR ', ') AS BadgeNames,
        GROUP_CONCAT(DISTINCT pt.Name SEPARATOR ', ') AS PostTypeNames
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
    GROUP BY p.Id, p.Title, p.Tags, p.ViewCount, p.Score, p.AnswerCount, u.DisplayName
), 
CommentsStats AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments
    FROM Comments
    GROUP BY PostId
),
EnhancedPostStats AS (
    SELECT 
        ps.*,
        COALESCE(cs.TotalComments, 0) AS TotalComments
    FROM PostStats ps
    LEFT JOIN CommentsStats cs ON ps.PostId = cs.PostId
)

SELECT 
    PostId,
    Title,
    Tags,
    ViewCount,
    Score,
    AnswerCount,
    TotalComments,
    OwnerDisplayName,
    BadgeNames,
    PostTypeNames
FROM EnhancedPostStats
WHERE Score > 5 
ORDER BY ViewCount DESC, AnswerCount DESC
LIMIT 10;
