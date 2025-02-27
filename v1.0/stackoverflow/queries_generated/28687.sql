WITH RankedUsers AS (
    SELECT
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(b.Id) AS BadgeCount,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
TopTags AS (
    SELECT 
        t.Id,
        t.TagName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(p.Id) AS PostCount,
        ROW_NUMBER() OVER (ORDER BY SUM(p.ViewCount) DESC) AS Rank
    FROM Tags t
    JOIN Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')::int[]) 
    GROUP BY t.Id
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId = 1 AND p.ViewCount > 1000
)

SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    tt.TagName,
    tt.TotalViews AS TagTotalViews,
    p.Title AS PopularPostTitle,
    p.ViewCount AS PopularPostViews
FROM RankedUsers u
JOIN TopTags tt ON u.Id = 
    (SELECT DISTINCT ub.UserId 
     FROM Badges ub 
     WHERE ub.UserId = u.Id 
     LIMIT 1)  -- Assuming 1 badge correlates with the user's interests
JOIN PopularPosts p ON p.Rank <= 10  -- Top 10 popular posts
WHERE u.Rank <= 10  -- Only considering top 10 users
ORDER BY u.Reputation DESC, tt.TotalViews DESC;
