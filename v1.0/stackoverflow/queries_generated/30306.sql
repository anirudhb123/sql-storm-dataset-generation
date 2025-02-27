WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with Questions only

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        rp.Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePosts rp ON p.ParentId = rp.PostId -- Joining to get answers to the questions
    WHERE 
        p.PostTypeId = 2 -- Only Answers
),

UserRank AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        RANK() OVER(ORDER BY SUM(p.Score) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000 -- Considering only reputable users
    GROUP BY 
        u.Id, u.DisplayName
),

TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT rp2.PostId) AS AnswerCount
    FROM 
        RecursivePosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Posts rp2 ON rp.PostId = rp2.ParentId
    WHERE 
        rp.Level = 1
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, u.DisplayName
    HAVING 
        COUNT(DISTINCT rp2.PostId) > 1 -- Only interested in questions with more than 1 answer
),

Result AS (
    SELECT 
        tq.Title AS QuestionTitle,
        tq.Score AS QuestionScore,
        tu.DisplayName AS UserName,
        tu.TotalScore AS UserTotalScore,
        tu.UserRank AS UserRank,
        tq.CommentCount,
        tq.AnswerCount,
        tq.CreationDate
    FROM 
        TopQuestions tq
    JOIN 
        UserRank tu ON tq.OwnerName = tu.DisplayName
    ORDER BY 
        tq.Score DESC,
        tu.UserRank
)

SELECT 
    QuestionTitle,
    QuestionScore,
    UserName,
    UserTotalScore,
    UserRank,
    CommentCount,
    AnswerCount,
    CreationDate
FROM 
    Result
WHERE 
    CreationDate >= NOW() - INTERVAL '1 year' -- Get questions from the last year
    AND UserRank <= 10 -- Only top 10 ranked users
ORDER BY 
    QuestionScore DESC;
