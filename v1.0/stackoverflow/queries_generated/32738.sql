WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreQuestions,
        SUM(CASE WHEN p.AnswerCount > 0 THEN 1 ELSE 0 END) AS QuestionsWithAnswers,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100 -- Consider users with significant reputation
    GROUP BY 
        u.Id, u.DisplayName
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS HistoryDate,
        p.Score,
        ph.Comment AS LastAction
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate >= DATEADD(MONTH, -1, GETDATE()) 
        AND ph.PostHistoryTypeId IN (10, 11, 12) -- Close, Reopen, Delete
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        RANK() OVER (ORDER BY SUM(ps.TotalViews) DESC) AS UserRank,
        ps.QuestionsAsked,
        ps.PositiveScoreQuestions,
        ps.QuestionsWithAnswers
    FROM 
        UserPostStats ps
    JOIN 
        Users u ON ps.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, ps.QuestionsAsked, ps.PositiveScoreQuestions, ps.QuestionsWithAnswers
)

SELECT 
    tu.UserRank,
    tu.DisplayName,
    tu.QuestionsAsked,
    tu.PositiveScoreQuestions,
    tu.QuestionsWithAnswers,
    rp.Title AS RecentPostTitle,
    ra.HistoryDate,
    ra.LastAction
FROM 
    TopUsers tu
LEFT JOIN 
    RecentActivity ra ON ra.PostId IN (SELECT Id FROM RankedPosts WHERE PostRank = 1 AND OwnerUserId = tu.Id)
LEFT JOIN 
    RankedPosts rp ON rp.OwnerUserId = tu.Id 
WHERE 
    tu.UserRank <= 10 -- Top 10 users  
ORDER BY 
    tu.UserRank, ra.HistoryDate DESC;
