WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM Posts
    WHERE PostTypeId = 1  -- Only consider Questions
    GROUP BY Tag
), 
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM TagCounts
    WHERE PostCount > 5  -- Filter tags that appear more than 5 times
),
MostRecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerName,
        pt.Name AS PostType
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE p.CreationDate >= (NOW() - INTERVAL '1 month') 
)
SELECT 
    t.Tag,
    t.PostCount AS TagPopularity,
    p.Title AS RecentPostTitle,
    p.OwnerName AS RecentPostOwner,
    p.CreationDate AS RecentPostDate,
    p.PostType AS RecentPostType
FROM TopTags t
LEFT JOIN MostRecentPosts p ON t.Tag LIKE '%' || p.Tags || '%'  -- Join with recent posts based on tags
ORDER BY t.PostCount DESC, p.CreationDate DESC;

This SQL query benchmarks string processing by analyzing popular tags from questions, counting their occurrences and linking them to the most recent posts containing those tags, thus showcasing the interaction between tag usage and recent activity on the platform.
