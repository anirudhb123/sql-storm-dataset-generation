WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        r.Id,
        r.Title,
        r.Score,
        r.ViewCount,
        r.AnswerCount,
        r.OwnerDisplayName
    FROM 
        RankedPosts r
    WHERE 
        r.rn <= 5
),
PostComments AS (
    SELECT 
        pc.PostId,
        COUNT(pc.Id) AS CommentCount
    FROM 
        Comments pc
    GROUP BY 
        pc.PostId
),
VotesSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(vs.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN tp.Score >= 100 THEN 'Hot Post'
        WHEN tp.Score >= 50 THEN 'Trending Post'
        ELSE 'Normal Post'
    END AS PostCategory
FROM 
    TopPosts tp
LEFT JOIN 
    PostComments pc ON tp.Id = pc.PostId
LEFT JOIN 
    VotesSummary vs ON tp.Id = vs.PostId
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;

WITH MonthlyActivity AS (
    SELECT 
        DATE_TRUNC('month', CreationDate) AS ActivityMonth,
        COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS AnswerCount
    FROM 
        Posts
    GROUP BY 
        ActivityMonth
),
YearlySummary AS (
    SELECT 
        EXTRACT(YEAR FROM ActivityMonth) AS Year,
        SUM(QuestionCount) AS TotalQuestions,
        SUM(AnswerCount) AS TotalAnswers
    FROM 
        MonthlyActivity
    GROUP BY 
        Year
)
SELECT 
    Year,
    TotalQuestions,
    TotalAnswers,
    (TotalQuestions * 1.0 / NULLIF(TotalAnswers, 0)) AS QuestionsPerAnswer
FROM 
    YearlySummary
ORDER BY 
    Year DESC;
