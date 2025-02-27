WITH TaggedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>') AS tag
        ON tag.value IS NOT NULL
    JOIN 
        Tags t ON t.TagName = TRIM(tag.value)
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionsAsked,
        COUNT(DISTINCT pa.Id) AS AnswersGiven
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1 -- Questions
    LEFT JOIN 
        Posts pa ON pa.ParentId = p.Id AND pa.PostTypeId = 2 -- Answers
    GROUP BY 
        u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.ViewCount,
        ua.UserDisplayName,
        ua.QuestionsAsked,
        ua.AnswersGiven
    FROM 
        TaggedPosts tp
    JOIN 
        Posts p ON p.Id = tp.PostId
    JOIN 
        UserActivity ua ON ua.UserId = p.OwnerUserId
),
RecentCloseReasons AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
        AND ph.CreationDate > DATEADD(year, -1, GETDATE()) -- Closed in the last year
)
SELECT 
    pm.Title,
    pm.CreationDate,
    pm.ViewCount,
    pm.UserDisplayName,
    pm.QuestionsAsked,
    pm.AnswersGiven,
    rc.CloseReason
FROM 
    PostMetrics pm
LEFT JOIN 
    RecentCloseReasons rc ON pm.PostId = rc.PostId
WHERE 
    pm.ViewCount > 100 
ORDER BY 
    pm.ViewCount DESC, pm.CreationDate DESC;
