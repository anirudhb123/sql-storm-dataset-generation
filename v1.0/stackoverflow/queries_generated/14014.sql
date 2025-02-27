-- Performance Benchmarking Query
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(AcceptedAnswers.AnswerId, 0) AS AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Posts AcceptedAnswers ON p.AcceptedAnswerId = AcceptedAnswers.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- only Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, AcceptedAnswers.AnswerId
)

SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AcceptedAnswerId,
    CommentCount,
    VoteCount
FROM 
    RankedPosts
WHERE 
    RN <= 100 -- retrieve the top 100 most recent questions
ORDER BY 
    CreationDate DESC;
