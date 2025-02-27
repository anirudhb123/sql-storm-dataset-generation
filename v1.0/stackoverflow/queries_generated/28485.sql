WITH TagStatistics AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPostCount,
        SUM(CASE WHEN Posts.ViewCount <= 100 THEN 1 ELSE 0 END) AS LessPopularPostCount,
        AVG(Posts.Score) AS AverageScore,
        STRING_AGG(DISTINCT Users.DisplayName, ', ') AS ActiveUsers
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '>')::int[])
    JOIN 
        Users ON Users.Id = Posts.OwnerUserId
    WHERE 
        Posts.PostTypeId = 1 -- Only consider Questions
    GROUP BY 
        Tags.TagName
),
RecentActivity AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Users.DisplayName AS Author,
        Comments.Text AS LastComment
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Comments.PostId = Posts.Id
    LEFT JOIN 
        Users ON Users.Id = Comments.UserId
    WHERE 
        Posts.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.PopularPostCount,
    ts.LessPopularPostCount,
    ts.AverageScore,
    ts.ActiveUsers,
    ra.PostId,
    ra.Title,
    ra.CreationDate,
    ra.Author,
    ra.LastComment
FROM
    TagStatistics ts
LEFT JOIN 
    RecentActivity ra ON ts.TagName = ANY(string_to_array(ra.Title, ' ')) 
ORDER BY 
    ts.PostCount DESC, ts.AverageScore DESC;

This SQL query combines two common tasks in data analysis: aggregating statistics about posts associated with different tags and retrieving recent activities related to those tags. It aims to provide insights into which tags are actively used, how many posts are associated with each tag, the average score of posts, as well as the most recent activity with those tags. 

The use of `WITH` clauses creates Common Table Expressions (CTEs) for better organization and readability. The `TagStatistics` CTE gathers metrics about posts and tags, while the `RecentActivity` CTE tracks the latest contributions. Finally, the main `SELECT` statement merges these two data sets, producing a comprehensive list that ranks tags by popularity and gives insights into recent activity.
