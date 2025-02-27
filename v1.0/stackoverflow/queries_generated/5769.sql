WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopQuestions AS (
    SELECT 
        r.* 
    FROM 
        RankedPosts r 
    WHERE 
        r.PostTypeId = 1 AND r.Rank <= 10
),
TopAnswers AS (
    SELECT 
        r.* 
    FROM 
        RankedPosts r 
    WHERE 
        r.PostTypeId = 2 AND r.Rank <= 10
),
Combined AS (
    SELECT 
        'Question' AS PostType,
        q.PostId,
        q.Title,
        q.ViewCount,
        q.Score,
        q.AnswerCount,
        q.OwnerDisplayName
    FROM 
        TopQuestions q
    UNION ALL
    SELECT 
        'Answer' AS PostType,
        a.PostId,
        a.Title,
        a.ViewCount,
        a.Score,
        0 AS AnswerCount, -- Answers do not have AnswerCount
        a.OwnerDisplayName
    FROM 
        TopAnswers a
)
SELECT 
    PostType,
    Title,
    ViewCount,
    Score,
    OwnerDisplayName,
    COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = c.PostId AND v.VoteTypeId = 2), 0) AS UpVotes,
    COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = c.PostId AND v.VoteTypeId = 3), 0) AS DownVotes
FROM 
    Combined c
ORDER BY 
    PostType, Score DESC;
