WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS ActiveUsers
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        t.TagName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AvgScore,
    ts.ActiveUsers,
    rph.CreationDate AS RecentActionDate,
    rph.UserDisplayName AS RecentActionUser,
    rph.Comment AS RecentActionComment
FROM 
    TagStatistics ts
LEFT JOIN 
    RecentPostHistory rph ON ts.PostCount > 0 AND rph.rn = 1
ORDER BY 
    ts.PostCount DESC,
    ts.AvgScore DESC;
