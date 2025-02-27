WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        SUM(v.VoteTypeId = 10) AS Deletions
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
), UserPostStatistics AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalBadges,
        UpVotes,
        DownVotes,
        Deletions,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM UserActivity
), PopularTags AS (
    SELECT 
        tags.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags
    JOIN Posts p ON p.Tags LIKE CONCAT('%<', tags.TagName, '>%')
    GROUP BY tags.TagName
    HAVING COUNT(p.Id) > 10
    ORDER BY PostCount DESC
), DetailedTags AS (
    SELECT 
        t.TagName,
        t.Count AS UsageCount,
        p.Title AS ExamplePostTitle,
        p.ViewCount AS ExamplePostViews,
        p.CreationDate AS ExamplePostCreationDate
    FROM Tags t
    JOIN Posts p ON t.ExcerptPostId = p.Id
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalComments,
    ups.TotalBadges,
    ups.UpVotes,
    ups.DownVotes,
    ups.Deletions,
    ups.Rank,
    pt.TagName AS PopularTag,
    dt.UsageCount AS TagUsageCount,
    dt.ExamplePostTitle,
    dt.ExamplePostViews,
    dt.ExamplePostCreationDate
FROM UserPostStatistics ups
LEFT JOIN PopularTags pt ON ups.TotalPosts > 0
LEFT JOIN DetailedTags dt ON dt.TagName = pt.TagName
WHERE ups.Rank <= 10
ORDER BY ups.Rank, pt.PostCount DESC;
