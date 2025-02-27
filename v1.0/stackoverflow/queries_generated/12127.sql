-- Performance benchmarking query for StackOverflow schema

WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(pb.FavoriteCount, 0)) AS TotalFavorites,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            SUM(FavoriteCount) AS FavoriteCount
        FROM Posts
        GROUP BY OwnerUserId
    ) pb ON pb.OwnerUserId = u.Id
    GROUP BY u.Id
),
PostInteractionStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(p.CreationDate) AS LastActivityDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title
)

SELECT
    u.DisplayName,
    ups.PostCount,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.TotalFavorites,
    ups.TotalViews,
    pis.PostId,
    pis.Title,
    pis.CommentCount,
    pis.VoteCount,
    pis.LastActivityDate
FROM UserPostStats ups
JOIN Users u ON ups.UserId = u.Id
JOIN PostInteractionStats pis ON pis.PostId IN (
    SELECT p.Id
    FROM Posts p
    WHERE p.OwnerUserId = u.Id
)
ORDER BY ups.PostCount DESC, ups.TotalViews DESC;
