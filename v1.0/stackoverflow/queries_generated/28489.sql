WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray,
        COALESCE(ps.AverageScore, 0) AS AveragePostScore,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int)
        )
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        (SELECT 
            PostId,
            AVG(Score) AS AverageScore
         FROM 
            Votes 
         WHERE 
            VoteTypeId IN (2,3) -- Upvotes and downvotes
         GROUP BY 
            PostId) ps ON ps.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2 -- Answers
    WHERE 
        p.PostTypeId IN (1, 2) -- Questions and Answers
    GROUP BY 
        p.Id, u.DisplayName, ps.AverageScore
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.CreationDate,
    pd.ViewCount,
    pd.AveragePostScore,
    pd.CommentCount,
    pd.AnswerCount,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    PostDetails pd
LEFT JOIN 
    UNNEST(pd.TagsArray) AS t(TagName) ON TRUE -- To flatten Tags array
GROUP BY 
    pd.PostId, pd.Title, pd.OwnerDisplayName, pd.CreationDate, pd.ViewCount, pd.AveragePostScore, pd.CommentCount, pd.AnswerCount
ORDER BY 
    pd.ViewCount DESC, pd.AveragePostScore DESC
LIMIT 10;

-- This query retrieves detailed information about questions and their related answers. 
-- It includes calculations for average scores based on votes, counts for comments and related answers,
-- and it concatenates tags associated with each post, allowing for complex string processing capabilities.
