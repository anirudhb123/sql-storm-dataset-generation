WITH TagWordCounts AS (
    SELECT
        t.TagName,
        COUNT(*) AS TagCount,
        SUM(LENGTH(p.Body) - LENGTH(REPLACE(p.Body, t.TagName, ''))) / LENGTH(t.TagName) AS WordOccurrence
    FROM
        Tags t
    JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY
        t.TagName
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownvotedPosts
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.Reputation
),
PopularTags AS (
    SELECT
        TagName,
        TagCount,
        WordOccurrence,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM
        TagWordCounts
)
SELECT
    u.UserId,
    u.Reputation,
    u.PostsCount,
    u.UpvotedPosts,
    u.DownvotedPosts,
    pt.TagName,
    pt.TagCount,
    pt.WordOccurrence
FROM
    UserReputation u
JOIN
    PopularTags pt ON u.PostsCount > 10 AND u.Reputation > 1000
WHERE
    pt.TagRank <= 10
ORDER BY
    u.Reputation DESC, pt.TagCount DESC;

This query consists of several Common Table Expressions (CTEs) to handle string processing and analysis effectively:
1. `TagWordCounts`: Counts the number of times each tag appears in the body of posts and sums the occurrences of each tag within the post's body.
2. `UserReputation`: Aggregates user data to retrieve their reputation, number of posts, and counts of posts that received positive and negative scores.
3. `PopularTags`: Ranks popular tags based on their occurrence across all posts.

The final SELECT query then joins these results to fetch users with significant activity (more than 10 posts and a reputation greater than 1000) while limiting the results to the top 10 most popular tags, ordered by user reputation and tag count.
