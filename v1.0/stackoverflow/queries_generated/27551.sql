WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
CloseReasonStats AS (
    SELECT 
        ph.Comment AS CloseReason, 
        COUNT(DISTINCT ph.PostId) AS ClosedPostCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.Comment
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ps.TagName,
        COALESCE(CAST(c.CloseReason AS VARCHAR), 'Open') AS CloseStatus,
        COALESCE(c.LastClosedDate, 'Not Closed') AS LastClosedDate
    FROM 
        Posts p
    LEFT JOIN 
        TagStats ps ON p.Tags LIKE CONCAT('%', ps.TagName, '%')
    LEFT JOIN 
        (
            SELECT 
                ph.PostId,
                ph.Comment,
                MAX(ph.CreationDate) AS LastClosedDate
            FROM 
                PostHistory ph
            WHERE 
                ph.PostHistoryTypeId = 10
            GROUP BY 
                ph.PostId, ph.Comment
        ) c ON p.Id = c.PostId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.ViewCount,
    COALESCE(ts.PostCount, 0) AS RelatedTagPostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AvgUserReputation,
    pm.CloseStatus,
    pm.LastClosedDate
FROM 
    PostMetrics pm
LEFT JOIN 
    TagStats ts ON pm.TagName = ts.TagName
ORDER BY 
    pm.ViewCount DESC, 
    pm.CreationDate DESC
LIMIT 100;
