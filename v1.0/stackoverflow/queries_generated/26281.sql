-- This SQL query benchmarks string processing by analyzing the tags used in posts, 
-- calculating the usage frequency of each tag and retrieving related user and post information.
-- The results include the most common tags with details about the associated posts and users.

WITH TagUsage AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Considering only questions
    GROUP BY 
        Unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><'))
),
CommonTags AS (
    SELECT 
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagUsage
    WHERE 
        TagCount > 1  -- Only considering tags used more than once
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        pu.DisplayName AS OwnerDisplayName,
        pu.Reputation AS OwnerReputation,
        pu.Location
    FROM 
        Posts p
    JOIN 
        Users pu ON p.OwnerUserId = pu.Id
    WHERE 
        p.PostTypeId = 1  -- Only include questions
)
SELECT 
    ct.TagName,
    ct.TagCount,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.AnswerCount,
    pd.OwnerDisplayName,
    pd.OwnerReputation,
    pd.Location
FROM 
    CommonTags ct
JOIN 
    PostDetails pd ON pd.Tags LIKE '%' || ct.TagName || '%'
ORDER BY 
    ct.Rank, pd.ViewCount DESC;  -- Order by the tag rank and view count of posts
