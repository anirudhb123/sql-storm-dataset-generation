WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotesCount,
        SUM(v.VoteTypeId = 3) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only consider questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
AnswerStats AS (
    SELECT 
        p.ParentId AS QuestionId,
        COUNT(a.Id) AS AnswerCount,
        AVG(a.Score) AS AverageScore
    FROM 
        Posts a
    WHERE 
        a.PostTypeId = 2 -- Only answers
    GROUP BY 
        p.ParentId
),
FinalScores AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotesCount,
        rp.DownVotesCount,
        COALESCE(as.AnswerCount, 0) AS AnswerCount,
        COALESCE(as.AverageScore, 0) AS AverageScore,
        CASE 
            WHEN rp.CommentCount > 10 THEN 'Active' 
            WHEN rp.UpVotesCount - rp.DownVotesCount > 5 THEN 'Popular'
            ELSE 'Normal' 
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        AnswerStats as ON rp.PostId = as.QuestionId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    CommentCount,
    UpVotesCount,
    DownVotesCount,
    AnswerCount,
    AverageScore,
    PostStatus
FROM 
    FinalScores
WHERE 
    CreationDate >= NOW() - INTERVAL '30 days' -- Filter for recent posts
ORDER BY 
    ViewCount DESC, AnswerCount DESC
LIMIT 50;
