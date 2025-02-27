WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViewCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),
PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
),

RecentEdits AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (4, 5, 24)  -- Edit Title, Edit Body, Suggested Edit Applied
    GROUP BY ph.PostId
)

SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalViewCount,
    ts.TotalScore,
    pi.Title,
    pi.CreationDate,
    pi.OwnerDisplayName,
    re.EditCount,
    re.LastEditDate
FROM TagStats ts
JOIN PostInfo pi ON pi.Tags LIKE '%' || ts.TagName || '%'
LEFT JOIN RecentEdits re ON re.PostId = pi.PostId
WHERE ts.PostCount > 0
ORDER BY ts.TotalScore DESC, ts.TotalViewCount DESC, re.LastEditDate DESC;
