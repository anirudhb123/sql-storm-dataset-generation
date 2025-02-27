-- Performance benchmarking query for the StackOverflow schema

-- This query will analyze the performance of fetching posts, including their tags, comments, and associated users

WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(t.TagName, ', ') AS Tags,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_arr ON TRUE -- Parsing tags
    LEFT JOIN 
        Tags t ON tag_arr = t.TagName
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Considering posts from the last year
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation
)
SELECT 
    *,
    EXTRACT(EPOCH FROM (NOW() - CreationDate)) AS AgeInSeconds -- Calculate the age of the post
FROM 
    PostDetails
ORDER BY 
    ViewCount DESC
LIMIT 100; -- Limit to top 100 posts
