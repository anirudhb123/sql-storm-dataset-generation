WITH RECURSIVE UserReputationHierarchy AS (
    SELECT Id, Reputation, CAST(DisplayName AS VARCHAR(50)) AS DisplayName, 1 AS Level
    FROM Users
    WHERE Id IN (SELECT OwnerUserId FROM Posts WHERE OwnerUserId IS NOT NULL)

    UNION ALL

    SELECT u.Id, u.Reputation, u.DisplayName, urh.Level + 1
    FROM Users u
    JOIN UserReputationHierarchy urh ON u.Id = urh.Id
    WHERE u.Reputation > urh.Reputation
),
BadgeCount AS (
    SELECT UserId, COUNT(*) AS TotalBadges
    FROM Badges
    GROUP BY UserId
),
PostAggregation AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(pv.VoteCount, 0) AS VoteCount,
        COALESCE(pm.CommentCount, 0) AS CommentCount,
        p.Score,
        p.OwnerUserId,
        CASE 
            WHEN p.AnswerCount > 0 THEN 'Answered'
            ELSE 'Unanswered'
        END AS PostStatus
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount
        FROM Votes
        GROUP BY PostId
    ) pv ON p.Id = pv.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) pm ON p.Id = pm.PostId
),
TopPosts AS (
    SELECT 
        pa.PostId, 
        pa.Title, 
        pa.CreationDate, 
        pa.VoteCount, 
        pa.CommentCount, 
        pa.Score, 
        pa.PostStatus,
        ROW_NUMBER() OVER (PARTITION BY pa.PostStatus ORDER BY pa.Score DESC) AS Rank
    FROM PostAggregation pa
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    bc.TotalBadges,
    tp.Title,
    tp.VoteCount,
    tp.CommentCount,
    tp.Score,
    tp.CreationDate,
    tp.PostStatus
FROM Users u
LEFT JOIN BadgeCount bc ON u.Id = bc.UserId
JOIN TopPosts tp ON u.Id = tp.OwnerUserId
WHERE tp.Rank <= 5
ORDER BY u.Reputation DESC, tp.Score DESC;
