WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    JOIN Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE p.PostTypeId = 1 -- Only questions
    GROUP BY p.Id
),
PostHistoryDetails AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT ph.UserDisplayName, ', ') AS Editors
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body and Tags
    GROUP BY p.Id
),
PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        rp.AnswerCount,
        rp.Tags,
        COALESCE(phd.LastEditDate, p.CreationDate) AS LastEditDate,
        COALESCE(phd.Editors, 'No edits') AS Editors
    FROM RankedPosts rp
    LEFT JOIN PostHistoryDetails phd ON rp.PostId = phd.PostId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.ViewCount,
    pm.CommentCount,
    pm.AnswerCount,
    pm.Tags,
    pm.LastEditDate,
    pm.Editors,
    EXTRACT(EPOCH FROM NOW() - pm.CreationDate) / 3600 AS AgeInHours,
    ROUND(pm.ViewCount::numeric / NULLIF(pm.CommentCount, 0), 2) AS ViewsPerComment,
    ROUND(pm.ViewCount::numeric / NULLIF(pm.AnswerCount, 0), 2) AS ViewsPerAnswer
FROM PostMetrics pm
ORDER BY pm.ViewCount DESC
LIMIT 100;
