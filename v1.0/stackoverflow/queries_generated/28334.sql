WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 24)  -- Edit Title, Edit Body, Suggested Edit Applied
    GROUP BY 
        ph.PostId
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.PositiveScoreCount,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalBounty,
    COALESCE(phe.EditCount, 0) AS TotalEdits,
    phe.LastEditDate
FROM 
    TagStats ts
JOIN 
    UserActivity ua ON ts.PostCount > 0
LEFT JOIN 
    PostHistoryStats phe ON phe.PostId IN (
        SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' || ts.TagName || '%'
    )
ORDER BY 
    ts.PostCount DESC, 
    ts.QuestionCount DESC 
LIMIT 10;
