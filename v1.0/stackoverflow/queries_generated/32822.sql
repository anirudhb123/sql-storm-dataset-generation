WITH RecursivePosts AS (
    -- CTE to find all posts and their parent questions
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.OwnerUserId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only find questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.OwnerUserId,
        rp.Level + 1
    FROM Posts p
    INNER JOIN RecursivePosts rp ON p.ParentId = rp.PostId
),
TagsWithCount AS (
    -- CTE to get tag count and most used tag
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(p.Id) DESC) AS TagRank
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY t.TagName
),
UserBadges AS (
    -- Fetch users and the number of their badges
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
UserPostStatistics AS (
    -- Calculate post statistics for users
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
)
SELECT 
    u.DisplayName,
    ub.BadgeCount,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalViews,
    t.TagName,
    t.PostCount AS TagPostCount,
    RANK() OVER (PARTITION BY u.Id ORDER BY ups.TotalViews DESC) AS ViewsRank
FROM UserPostStatistics ups
JOIN Users u ON ups.UserId = u.Id
JOIN UserBadges ub ON u.Id = ub.UserId
JOIN TagsWithCount t ON t.TagRank = 1 -- Join with most used tag
LEFT JOIN RecursivePosts rp ON rp.OwnerUserId = u.Id
WHERE ub.BadgeCount > 0 -- Only include users with badges
ORDER BY ups.TotalViews DESC, u.DisplayName;
