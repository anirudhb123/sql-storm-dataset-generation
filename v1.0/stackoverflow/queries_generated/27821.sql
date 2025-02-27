WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    WHERE PostTypeId = 1 -- Only questions
    GROUP BY TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM TagCounts
    WHERE PostCount > 5 -- Consider only tags with more than 5 posts
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
JOIN Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
JOIN UserActivity ua ON p.OwnerUserId = ua.UserId
GROUP BY t.TagName
ORDER BY ActiveUserCount DESC, AvgPostsPerUser DESC;
This SQL query benchmarks string processing by:

1. **Extracting tags** from the `Tags` column of the `Posts` table for questions, using `string_to_array`.
2. **Counting occurrences** of each tag to find the most popular ones.
3. **Filtering** for tags with more than 5 uses.
4. Aggregating user activity statistics like total posts, comment scores, and votes.
5. Joining tag and user data to find how many active users are associated with each popular tag and calculating averages and total upvotes/downvotes.
6. Finally, it orders the results by active user count and average posts per user.
