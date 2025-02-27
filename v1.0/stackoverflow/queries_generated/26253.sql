WITH PostTags AS (
    SELECT 
        P.Id AS PostId, 
        UNNEST(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')) AS TagName,
        P.CreationDate AS PostCreationDate,
        U.DisplayName AS PostOwner
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  -- Filtering to only questions
),
AggregatedTags AS (
    SELECT 
        TagName, 
        COUNT(*) AS TagCount,
        MIN(PostCreationDate) AS FirstUsed,
        MAX(PostCreationDate) AS LastUsed
    FROM 
        PostTags
    GROUP BY 
        TagName
),
MostActiveTags AS (
    SELECT 
        TagName,
        TagCount,
        FirstUsed,
        LastUsed
    FROM 
        AggregatedTags
    WHERE 
        TagCount >= 5  -- Only tags used more than 5 times
    ORDER BY 
        TagCount DESC
    LIMIT 10  -- Top 10 most used active tags
),
PostsUsingMostActiveTags AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        T.TagName
    FROM 
        Posts P
    JOIN 
        PostTags PT ON P.Id = PT.PostId
    JOIN 
        MostActiveTags T ON PT.TagName = T.TagName
)
SELECT 
    U.DisplayName AS UserName,
    COUNT(DISTINCT PUM.PostId) AS PostsCount,
    SUM(PUM.Score) AS TotalScore,
    SUM(PUM.ViewCount) AS TotalViews,
    ARRAY_AGG(DISTINCT PUM.TagName) AS AssociatedTags
FROM 
    Users U
JOIN 
    PostsUsingMostActiveTags PUM ON U.Id = PUM.OwnerUserId
GROUP BY 
    U.DisplayName
ORDER BY 
    TotalScore DESC
LIMIT 5;

This SQL query operates on the Stack Overflow schema and accomplishes the following:

1. **PostTags CTE**: Extracts the tags from post entries specifically for questions (PostTypeId = 1), and associates each with the post creation date and the user who owns the post.

2. **AggregatedTags CTE**: Counts occurrences of each tag, finds the first and last use dates for each tag.

3. **MostActiveTags CTE**: Filters for the top 10 most active tags that have been used more than 5 times.

4. **PostsUsingMostActiveTags CTE**: Compiles a list of all posts that use these active tags along with pertinent post details.

5. The final SELECT statement gathers users who posted those active tags, counting their total posts, summarizing their scores and views, and aggregating the associated tags.

This query reflects complex string processing operations, particularly in the use of `string_to_array` and the filtering of tag data, while analyzing interactions by users with pervasive tags.
