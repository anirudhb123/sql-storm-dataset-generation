WITH RecursiveTags AS (
    SELECT 
        Tags.TagName,
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.LastActivityDate,
        Posts.ViewCount,
        Posts.AnswerCount,
        Posts.CommentCount,
        Posts.Score,
        Posts.Body,
        Posts.Tags AS OriginalTags
    FROM 
        Posts 
        JOIN Tags ON Tags.Id = Posts.Id
    WHERE 
        Posts.PostTypeId = 1  -- Questions only
    
    UNION ALL
    
    SELECT 
        Tags.TagName,
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.LastActivityDate,
        Posts.ViewCount,
        Posts.AnswerCount,
        Posts.CommentCount,
        Posts.Score,
        Posts.Body,
        Posts.Tags AS OriginalTags
    FROM 
        Posts 
        JOIN PostLinks ON PostLinks.PostId = Posts.Id
        JOIN Tags ON Tags.Id = Posts.Id
    WHERE 
        PostLinks.LinkTypeId = 1  -- Linked Posts
)

SELECT 
    R.TagName,
    COUNT(DISTINCT R.PostId) AS TotalPosts,
    SUM(R.ViewCount) AS TotalViews,
    AVG(R.Score) AS AverageScore,
    AVG(R.AnswerCount) AS AverageAnswers,
    AVG(R.CommentCount) AS AverageComments,
    STRING_AGG(DISTINCT R.Tags, ', ') AS CombinedTags,
    MAX(R.LastActivityDate) AS MostRecentActivity,
    MIN(R.CreationDate) AS EarliestPost
FROM 
    RecursiveTags R
GROUP BY 
    R.TagName
ORDER BY 
    TotalPosts DESC
LIMIT 10;
This SQL query recursively retrieves and aggregates data on the most relevant tags associated with questions, summarizing interaction metrics per tag, including total number of posts, views, scores, and combined tags. It highlights trends in community engagement and content creation on the platform.
