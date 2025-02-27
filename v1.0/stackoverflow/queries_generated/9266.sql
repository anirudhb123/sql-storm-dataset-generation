WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
BadgeActivity AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        pt.Name AS PostType,
        COUNT(c.Id) AS TotalComments,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS TotalUpvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS TotalDownvotes
    FROM Posts p
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, pt.Name
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.AcceptedAnswers,
    ua.Upvotes,
    ua.Downvotes,
    ua.CommentCount,
    ua.LastPostDate,
    ba.BadgeCount,
    ba.GoldBadges,
    ba.SilverBadges,
    ba.BronzeBadges,
    ps.PostId,
    ps.Title AS PostTitle,
    ps.ViewCount,
    ps.Score AS PostScore,
    ps.PostType,
    ps.TotalComments,
    ps.TotalUpvotes AS PostUpvotes,
    ps.TotalDownvotes AS PostDownvotes
FROM UserActivity ua
LEFT JOIN BadgeActivity ba ON ua.UserId = ba.UserId
LEFT JOIN PostStatistics ps ON ps.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ua.UserId)
ORDER BY ua.PostCount DESC, ua.LastPostDate DESC;
