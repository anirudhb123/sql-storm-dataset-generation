WITH tag_frequency AS (
    SELECT 
        UNNEST(string_to_array(Tags, '><')) AS Tag,
        COUNT(*) AS Frequency
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Filtering only questions
    GROUP BY 
        Tag
),
top_tags AS (
    SELECT 
        Tag,
        Frequency,
        ROW_NUMBER() OVER (ORDER BY Frequency DESC) AS Rank
    FROM 
        tag_frequency
    WHERE 
        Frequency > 5  -- Only considering tags with more than 5 occurrences
),
posts_with_top_tags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        T.Tag
    FROM 
        Posts p
    JOIN 
        top_tags T ON T.Tag = ANY (string_to_array(p.Tags, '><'))
)
SELECT 
    p.PostId,
    p.Title,
    COUNT(C.comment) AS CommentCount,
    AVG(U.Reputation) AS AvgReputation,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    STRING_AGG(DISTINCT T.Tag, ', ') AS RelatedTags
FROM 
    posts_with_top_tags p
LEFT JOIN 
    Comments C ON C.PostId = p.PostId
LEFT JOIN 
    Users U ON U.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON b.UserId = U.Id
GROUP BY 
    p.PostId, p.Title
ORDER BY 
    CommentCount DESC, AvgReputation DESC
LIMIT 10;
