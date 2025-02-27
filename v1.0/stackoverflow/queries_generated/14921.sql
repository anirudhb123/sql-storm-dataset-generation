-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), p.Id) AS FinalAnswerId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month' -- Adjust timeframe as necessary
    GROUP BY 
        p.Id
),
AnswerStats AS (
    SELECT 
        a.ParentId AS QuestionId,
        COUNT(a.Id) AS AnswerCount,
        MAX(a.CreationDate) AS LastAnswerDate
    FROM 
        Posts a
    WHERE 
        a.PostTypeId = 2 -- Answer
    GROUP BY 
        a.ParentId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    COALESCE(as.AnswerCount, 0) AS TotalAnswers,
    as.LastAnswerDate,
    CASE 
        WHEN ps.FinalAnswerId IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS HasAcceptedAnswer
FROM 
    PostStats ps
LEFT JOIN 
    AnswerStats as ON ps.PostId = as.QuestionId
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC;
