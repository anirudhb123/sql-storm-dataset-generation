
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE PostTypeId = 1 
    GROUP BY TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        @rank := @rank + 1 AS Rank
    FROM TagCounts, (SELECT @rank := 0) r
    WHERE PostCount > 5 
    ORDER BY PostCount DESC
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    t.TagName,
    COUNT(ua.UserId) AS ActiveUserCount,
    AVG(ua.PostsCount) AS AvgPostsPerUser,
    SUM(ua.Upvotes) AS TotalUpvotes,
    SUM(ua.Downvotes) AS TotalDownvotes
FROM TopTags t
JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
JOIN UserActivity ua ON p.OwnerUserId = ua.UserId
GROUP BY t.TagName
ORDER BY ActiveUserCount DESC, AvgPostsPerUser DESC;
