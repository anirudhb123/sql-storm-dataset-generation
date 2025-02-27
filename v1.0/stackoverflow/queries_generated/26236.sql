WITH PostHistoryAggregated AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(ph.Id) AS EditingActions,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate,
        SUM(
            CASE 
                WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 
                ELSE 0 
            END
        ) AS TotalEdits,
        STRING_AGG(DISTINCT tags.TagName, ', ') AS TagList,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId 
    LEFT JOIN Tags tags ON tags.Id = p.Id  -- Assuming Tags may link to posts (this part should be handled based on actual structure)
    LEFT JOIN Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.ViewCount > 100  -- Focus on popular posts
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
EditDifference AS (
    SELECT
        PostId,
        Title,
        TotalEdits,
        FirstEditDate,
        LastEditDate,
        EditingActions,
        AgeInDays AS AgeAtLastEdit,
        CASE 
            WHEN LastEditDate IS NOT NULL 
            THEN DATEDIFF(DAY, CreationDate, LastEditDate)
            ELSE NULL 
        END AS DaysSinceLastEdit,
        TagList,
        CommentCount
    FROM (
        SELECT 
            *,
            DATEDIFF(DAY, CreationDate, CURRENT_TIMESTAMP) AS AgeInDays
        FROM PostHistoryAggregated
    ) AS SubQuery
)

SELECT 
    p.PostId,
    p.Title,
    p.TagList,
    p.CommentCount,
    p.TotalEdits,
    p.FirstEditDate,
    p.LastEditDate,
    p.EditingActions,
    p.AgeAtLastEdit,
    p.DaysSinceLastEdit
FROM EditDifference p
WHERE p.TotalEdits > 5  -- Focus on posts with many edits
ORDER BY p.DaysSinceLastEdit DESC, p.ViewCount DESC -- Most edited and viewed posts at the top
LIMIT 10;  -- Limit the output to the top 10 posts
