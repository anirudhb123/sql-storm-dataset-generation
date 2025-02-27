
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS TotalWikiPosts,
        SUM(p.ViewCount) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', n.n), '>', -1) AS TagName,
        COUNT(*) AS TagUsageCount
    FROM Posts
    JOIN (SELECT a.N + 1 AS n FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= n.n
    WHERE Tags IS NOT NULL
    GROUP BY TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagUsageCount
    FROM PopularTags
    ORDER BY TagUsageCount DESC
    LIMIT 10
),
PostInteractions AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagsUsed
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Tags t ON FIND_IN_SET(t.TagName, p.Tags) > 0
    GROUP BY p.Id
)
SELECT 
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalWikiPosts,
    ups.TotalViews,
    t.TagName,
    t.TagUsageCount,
    pi.CommentCount,
    pi.VoteCount,
    pi.TagsUsed
FROM UserPostStats ups
JOIN PostInteractions pi ON ups.UserId = pi.PostId
JOIN TopTags t ON FIND_IN_SET(t.TagName, pi.TagsUsed) > 0
ORDER BY ups.TotalPosts DESC, t.TagUsageCount DESC;
