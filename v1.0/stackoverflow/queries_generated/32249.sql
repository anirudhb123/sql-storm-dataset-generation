WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursiveCTE r ON p.ParentId = r.PostId
    WHERE 
        p.PostTypeId = 2 -- Only answers
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostedQuestions,
        COUNT(DISTINCT a.Id) AS AnsweredQuestions,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        AVG(COALESCE(b.Reputation, 0)) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2 -- Answers
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Users b ON b.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

PostHistoryAnalysis AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        MIN(ph.CreationDate) OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS FirstEditDate,
        COUNT(*) OVER (PARTITION BY ph.PostId) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10, 11) -- Edits and closure events
),

FinalResult AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.PostedQuestions,
        us.AnsweredQuestions,
        us.TotalBounties,
        us.AverageReputation,
        ph.PostId,
        ph.FirstEditDate,
        ph.EditCount,
        r.Level AS AnswerLevel
    FROM 
        UserStats us
    LEFT JOIN 
        PostHistoryAnalysis ph ON us.UserId = ph.UserId
    LEFT JOIN 
        RecursiveCTE r ON ph.PostId = r.PostId
    WHERE 
        us.PostedQuestions > 0
)

SELECT 
    fr.DisplayName,
    fr.PostedQuestions,
    fr.AnsweredQuestions,
    fr.TotalBounties,
    fr.AverageReputation,
    COUNT(DISTINCT fr.PostId) AS UniquePostEdits,
    AVG(DATEDIFF('second', fr.FirstEditDate, NOW())) AS AvgTimeToEdit,
    SUM(CASE WHEN fr.AnswerLevel IS NOT NULL THEN 1 ELSE 0 END) AS AnsweredLevelQuestions
FROM 
    FinalResult fr
GROUP BY 
    fr.DisplayName, 
    fr.PostedQuestions, 
    fr.AnsweredQuestions, 
    fr.TotalBounties, 
    fr.AverageReputation
ORDER BY 
    fr.TotalBounties DESC, 
    fr.AverageReputation DESC;
