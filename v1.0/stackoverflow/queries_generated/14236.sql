-- Performance benchmarking query to assess the number of questions, answers and their interactions

WITH QuestionStats AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        COUNT(a.Id) AS AnswerCount,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END) AS AcceptedCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),

AnswerStats AS (
    SELECT 
        a.ParentId AS QuestionId,
        COUNT(a.Id) AS TotalAnswers,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts a
    LEFT JOIN 
        Votes v ON v.PostId = a.Id
    WHERE 
        a.PostTypeId = 2 -- Only answers
    GROUP BY 
        a.ParentId
)

SELECT 
    qs.QuestionId,
    qs.Title,
    qs.CreationDate,
    COALESCE(qs.AnswerCount, 0) AS TotalAnswers,
    COALESCE(qs.CommentCount, 0) AS TotalComments,
    COALESCE(qs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(qs.DownVotes, 0) AS TotalDownVotes,
    COALESCE(as.TotalAnswers, 0) AS TotalAnswersByParent
FROM 
    QuestionStats qs
LEFT JOIN 
    AnswerStats as ON qs.QuestionId = as.QuestionId
ORDER BY 
    qs.CreationDate DESC;
