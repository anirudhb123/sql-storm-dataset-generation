WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Questions only

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        Posts rp ON p.ParentId = rp.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(p.AnswerCount), 0) AS TotalAnswers,
        COALESCE(SUM(p.CommentCount), 0) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Body, Tags
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    up.DisplayName AS UserName,
    up.TotalViews,
    up.TotalAnswers,
    up.TotalComments,
    rp.PostId,
    rp.Title,
    COALESCE(ph.EditCount, 0) AS TotalEdits,
    ph.LastEditDate,
    rp.CreationDate AS QuestionDate,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - rp.CreationDate))/3600 AS HoursSinceCreation,
    CASE
        WHEN ph.LastEditDate IS NOT NULL THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus
FROM 
    UserStats up
JOIN 
    RecursivePosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    PostHistoryInfo ph ON rp.PostId = ph.PostId
WHERE 
    up.Reputation > 1000  -- Only filter for high-reputation users
ORDER BY 
    up.TotalAnswers DESC, 
    rp.CreationDate DESC
LIMIT 100;
