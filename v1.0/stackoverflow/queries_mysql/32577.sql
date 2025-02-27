
WITH RECURSIVE PostViews AS (
    SELECT 
        p.Id, 
        COUNT(v.Id) AS VoteCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY p.Id
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName, 
        SUM(CASE WHEN p.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostCount,
        SUM(CASE WHEN c.UserId IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName ASC) AS Tags
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT DISTINCT 
            p.Id AS PostId,
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1) AS TagName
        FROM Posts p
        JOIN (
            SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
            UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
        ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
    ) AS t ON p.Id = t.PostId
    GROUP BY u.Id, u.DisplayName
),
TaggedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(th.PostCount, 0) AS TagPostCount,
        vp.VoteCount,
        vp.Upvotes,
        vp.Downvotes
    FROM Posts p
    LEFT JOIN (
        SELECT 
            t.Id,
            COUNT(DISTINCT p.Id) AS PostCount
        FROM Tags t
        LEFT JOIN Posts p ON FIND_IN_SET(t.TagName, REPLACE(p.Tags, '>', ',')) > 0
        GROUP BY t.Id
    ) AS th ON th.Id = p.Id
    LEFT JOIN PostViews vp ON vp.Id = p.Id
    WHERE p.CreationDate >= NOW() - INTERVAL 6 MONTH
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostCount,
    u.CommentCount,
    u.TotalViews,
    p.Title,
    p.TagPostCount,
    p.VoteCount,
    p.Upvotes,
    p.Downvotes
FROM UserEngagement u
CROSS JOIN TaggedPosts p
ORDER BY 
    u.TotalViews DESC,
    p.TagPostCount DESC
LIMIT 100;
