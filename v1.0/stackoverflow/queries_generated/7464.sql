WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 10 -- More than 10 questions
),
TopPostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostAnalysis AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        COALESCE(pc.CommentCount, 0) AS TotalComments,
        COALESCE(pc.LastCommentDate, '1900-01-01') AS LastCommentDate,
        mu.QuestionCount AS UserQuestionCount,
        mu.TotalScore AS UserTotalScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopPostComments pc ON rp.PostID = pc.PostId
    JOIN 
        MostActiveUsers mu ON rp.OwnerUserId = mu.UserId
)
SELECT 
    PostID,
    Title,
    OwnerDisplayName,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    TotalComments,
    LastCommentDate,
    UserQuestionCount,
    UserTotalScore
FROM 
    PostAnalysis
WHERE 
    PostRank = 1
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 50;
