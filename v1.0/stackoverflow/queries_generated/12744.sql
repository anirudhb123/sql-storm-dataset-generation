-- Performance Benchmarking Query for StackOverflow Schema

WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(ph.UserId) AS LastEditedBy
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.TotalViews,
        ups.TotalScore,
        ph.EditCount,
        ph.LastEditDate,
        ph.LastEditedBy
    FROM 
        UserPostStats ups
    LEFT JOIN 
        PostHistoryStats ph ON ups.PostCount > 0 -- Only include users with posts
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews,
    TotalScore,
    EditCount,
    LastEditDate,
    LastEditedBy
FROM 
    FinalStats
ORDER BY 
    TotalScore DESC, PostCount DESC
LIMIT 100; -- Limit to top 100 users for benchmarking
