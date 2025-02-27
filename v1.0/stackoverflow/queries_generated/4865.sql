WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS LatestEditDate,
        MAX(ph.PostHistoryTypeId) AS LatestChangeType
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.AvgScore,
    COALESCE(rph.LatestEditDate, 'No edits') AS LastEditDate,
    CASE 
        WHEN rph.LatestChangeType IS NULL THEN 'No changes'
        WHEN rph.LatestChangeType = 10 THEN 'Closed'
        WHEN rph.LatestChangeType = 11 THEN 'Reopened'
        ELSE 'Edited/Modified'
    END AS LastChangeType
FROM 
    UserPostStats ups
LEFT JOIN 
    RecentPostHistory rph ON rph.PostId IN (
        SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ups.UserId
    )
ORDER BY 
    ups.AvgScore DESC, ups.TotalPosts DESC
LIMIT 50;
