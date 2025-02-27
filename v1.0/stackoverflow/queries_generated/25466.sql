WITH TagCounts AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN Posts.AnswerCount ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswersGiven,
        ARRAY_AGG(DISTINCT Users.DisplayName) AS ActiveUsers,
        STRING_AGG(DISTINCT Posts.Title, '; ') AS RelevantPostTitles
    FROM 
        Posts
    JOIN 
        unnest(string_to_array(Posts.Tags, '<>')) AS Tag ON Tag = Tags.TagName
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    WHERE 
        Posts.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        Tags.TagName
), 
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalAnswers,
        TotalAnswersGiven,
        ActiveUsers,
        RelevantPostTitles,
        DENSE_RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
)
SELECT 
    TagName,
    PostCount,
    TotalAnswers,
    TotalAnswersGiven,
    ActiveUsers,
    RelevantPostTitles
FROM 
    TopTags
WHERE 
    TagRank <= 10
ORDER BY 
    PostCount DESC;
This SQL query benchmarks string processing by calculating tag-related metrics from posts created in the last year. It aggregates data such as the number of posts per tag, the total answers associated with those posts, and the display names of users who created the posts. The top 10 tags based on post count are selected, providing insights into popular tags and user engagement.
