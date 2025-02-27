WITH RECURSIVE TagHierarchy AS (
    SELECT TagName, COUNT(*) AS TotalPosts
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY TagName
    HAVING COUNT(*) >= 10
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Comments c ON c.UserId = u.Id
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RecentActivityRank
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    WHERE p.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY p.Id, p.Title
),
ActiveUsers AS (
    SELECT 
        ua.DisplayName,
        ua.Upvotes,
        ua.Downvotes,
        ua.CommentCount,
        ua.PostCount,
        PS.PostId,
        PS.TotalCommentScore,
        PS.VoteCount
    FROM UserActivity ua
    JOIN PostStatistics PS ON ua.PostCount > 0
    ORDER BY ua.Upvotes DESC
    LIMIT 10
)
SELECT 
    th.TagName,
    COUNT(DISTINCT ps.PostId) AS PostCount,
    AVG(ps.TotalCommentScore) AS AvgCommentScore,
    AVG(ps.VoteCount) AS AvgVoteCount,
    au.DisplayName,
    au.Upvotes,
    au.CommentCount
FROM TagHierarchy th
JOIN Posts p ON p.Tags LIKE '%' || th.TagName || '%'
JOIN PostStatistics ps ON p.Id = ps.PostId
JOIN ActiveUsers au ON ps.PostId IN (
    SELECT PostId FROM Posts WHERE OwnerUserId = au.UserId
)
GROUP BY th.TagName, au.DisplayName
HAVING COUNT(DISTINCT ps.PostId) > 5
ORDER BY PostCount DESC, AvgVoteCount DESC;
