
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM Posts
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
        UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE PostTypeId = 1
    GROUP BY Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        @rank := @rank + 1 AS Rank
    FROM TagCounts, (SELECT @rank := 0) r
    ORDER BY PostCount DESC
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        p.Id AS PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        MIN(ph.CreationDate) AS FirstHistoryDate,
        MAX(ph.CreationDate) AS LastHistoryDate,
        GROUP_CONCAT(DISTINCT ph.Comment SEPARATOR ', ') AS Comments
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, ph.PostHistoryTypeId
),
RecentActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        p.LastActivityDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > NOW() - INTERVAL 1 MONTH
    GROUP BY p.Id, p.Title, u.DisplayName, p.CreationDate, p.LastActivityDate
)
SELECT 
    t.Tag,
    t.PostCount,
    u.DisplayName AS User,
    u.TotalPosts,
    u.TotalComments,
    u.PositivePosts,
    r.PostId,
    r.Title,
    r.OwnerName,
    r.CreationDate,
    r.LastActivityDate,
    r.CommentCount,
    r.UpvoteCount,
    phs.HistoryCount,
    phs.FirstHistoryDate,
    phs.LastHistoryDate,
    phs.Comments
FROM TopTags t
JOIN UserPostStats u ON u.TotalPosts > 10 
JOIN RecentActivePosts r ON r.CommentCount > 5 
JOIN PostHistorySummary phs ON phs.PostId = r.PostId
WHERE t.Rank <= 5 
ORDER BY t.PostCount DESC, u.TotalPosts DESC;
