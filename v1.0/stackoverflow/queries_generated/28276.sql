WITH QuestionTags AS (
    SELECT 
        id AS PostId,
        Title,
        Tags,
        OwnerUserId,
        AnswerCount,
        CommentCount,
        Score,
        CreationDate
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
TagStats AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        QuestionTags
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagStats
    WHERE 
        TagCount > 5  -- Only take tags with more than 5 questions
),
TopQuestions AS (
    SELECT 
        q.PostId,
        q.Title,
        q.CreationDate,
        t.Tag
    FROM 
        QuestionTags q
    INNER JOIN 
        TopTags t ON t.Tag = ANY(string_to_array(substring(q.Tags, 2, length(q.Tags) - 2), '><'))
    ORDER BY 
        q.Score DESC, q.CreationDate DESC
)
SELECT 
    q.Title,
    q.CreationDate,
    t.Tag,
    u.DisplayName AS Owner,
    u.Reputation,
    q.AnswerCount,
    q.CommentCount
FROM 
    TopQuestions q
JOIN 
    Users u ON q.OwnerUserId = u.Id
WHERE 
    q.CreationDate > NOW() - INTERVAL '30 days'  -- Limit to the last 30 days
ORDER BY 
    q.Score DESC, 
    q.CreationDate DESC
LIMIT 10;
