WITH RecursiveTagCounts AS (
    -- This CTE counts the number of distinct users contributed to each tag
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.OwnerUserId) AS UserCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.PostTypeId = 1  -- Only consider Questions
    GROUP BY 
        t.TagName
),
TagActivity AS (
    -- This CTE retrieves the activity metrics related to each tag
    SELECT 
        t.TagName,
        COUNT(DISTINCT ph.Id) AS EditCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        MAX(p.CreationDate) AS LastActiveDate,
        MIN(b.Date) AS FirstBadgeDate
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%' AND p.PostTypeId = 1
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, Tags edits
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    GROUP BY 
        t.TagName
),
CombinedTagMetrics AS (
    -- Combine counts from both CTEs and create a comprehensive view
    SELECT 
        rtc.TagName,
        rtc.UserCount,
        ta.EditCount,
        ta.CommentCount,
        ta.LastActiveDate,
        ta.FirstBadgeDate,
        -- Calculate average activities based on user count
        CASE 
            WHEN rtc.UserCount > 0 THEN (ta.EditCount * 1.0 / rtc.UserCount)
            ELSE 0
        END AS AvgEditsPerUser,
        CASE 
            WHEN rtc.UserCount > 0 THEN (ta.CommentCount * 1.0 / rtc.UserCount)
            ELSE 0
        END AS AvgCommentsPerUser
    FROM 
        RecursiveTagCounts rtc
    JOIN 
        TagActivity ta ON rtc.TagName = ta.TagName
)

SELECT 
    TagName,
    UserCount,
    EditCount,
    CommentCount,
    LastActiveDate,
    FirstBadgeDate,
    AvgEditsPerUser,
    AvgCommentsPerUser
FROM 
    CombinedTagMetrics
ORDER BY 
    UserCount DESC, EditCount DESC;
