
WITH RankedQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
        AND p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
),
TopQuestions AS (
    SELECT 
        q.QuestionId,
        q.Title,
        q.OwnerName,
        q.ViewCount,
        q.AnswerCount
    FROM 
        RankedQuestions q
    WHERE 
        q.Rank <= 10
),
QuestionStatistics AS (
    SELECT 
        tq.QuestionId,
        tq.Title,
        tq.OwnerName,
        tq.ViewCount,
        tq.AnswerCount,
        COALESCE(SUM(CASE WHEN vt.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN vt.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount
    FROM 
        TopQuestions tq
    LEFT JOIN 
        Votes vt ON tq.QuestionId = vt.PostId
    LEFT JOIN 
        Comments c ON tq.QuestionId = c.PostId
    GROUP BY 
        tq.QuestionId, tq.Title, tq.OwnerName, tq.ViewCount, tq.AnswerCount
)
SELECT 
    qs.QuestionId,
    qs.Title,
    qs.OwnerName,
    qs.ViewCount,
    qs.AnswerCount,
    qs.UpVotes,
    qs.DownVotes,
    qs.CommentCount,
    (qs.UpVotes - qs.DownVotes) AS Score
FROM 
    QuestionStatistics qs
ORDER BY 
    Score DESC;
