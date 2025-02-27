WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.LastActivityDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Only questions from the last year
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Tags,
    rp.CreationDate,
    rp.LastActivityDate,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    COALESCE(a.AnswerCount, 0) AS AnswerCount,
    COALESCE(s.Score, 0) AS PostScore
FROM 
    RankedPosts rp
LEFT JOIN 
    (SELECT 
         PostId, 
         COUNT(*) AS CommentCount 
     FROM 
         Comments 
     GROUP BY PostId) c ON rp.PostId = c.PostId
LEFT JOIN 
    (SELECT 
         ParentId AS PostId, 
         COUNT(*) AS AnswerCount 
     FROM 
         Posts 
     WHERE 
         PostTypeId = 2 -- Only answers
     GROUP BY ParentId) a ON rp.PostId = a.PostId
LEFT JOIN 
    (SELECT 
         PostId, 
         SUM(Score) AS Score 
     FROM 
         Votes 
     WHERE 
         VoteTypeId = 2 -- Only upvotes
     GROUP BY PostId) s ON rp.PostId = s.PostId
WHERE 
    rp.TagRank <= 5 -- Select top 5 posts for each tag
ORDER BY 
    rp.Tags, rp.LastActivityDate DESC;
