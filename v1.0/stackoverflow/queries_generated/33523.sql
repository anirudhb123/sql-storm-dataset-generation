WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RevNum
    FROM 
        PostHistory ph
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(c.Score, 0)) AS CommentScore,
        MAX(p.CreationDate) AS LastQuestionDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
CloseReasonSummary AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS CloseCount,
        COUNT(DISTINCT ph.PostId) AS DistinctPostsClosed
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  -- Close action
    GROUP BY 
        ph.UserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.QuestionCount,
    ua.TotalScore,
    ua.CommentScore,
    cr.CloseCount,
    cr.DistinctPostsClosed,
    u.CreationDate,
    CASE 
        WHEN ua.LastQuestionDate IS NOT NULL THEN
            DATEDIFF(CURRENT_TIMESTAMP, ua.LastQuestionDate)
        ELSE 
            NULL
    END AS DaysSinceLastQuestion
FROM 
    UserActivity ua
LEFT JOIN 
    CloseReasonSummary cr ON ua.UserId = cr.UserId
JOIN 
    Users u ON ua.UserId = u.Id
WHERE 
    ua.QuestionCount > 0
ORDER BY 
    ua.TotalScore DESC,
    cr.CloseCount DESC
LIMIT 100;

