WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCreated,
        SUM(v.CreationDate IS NOT NULL) AS VotesReceived,
        COUNT(DISTINCT b.Id) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id AND v.PostId IN (SELECT Id FROM Posts where OwnerUserId = u.Id)
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStatistics AS (
    SELECT 
        ph.PostId,
        p.Title,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(ph.Comment, '; ') AS EditComments
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 24) -- Editing title, body, tags, suggested edits
    GROUP BY 
        ph.PostId, p.Title
)

SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.TotalViews,
    ts.AverageScore,
    au.DisplayName AS ActiveUser,
    au.PostsCreated,
    au.VotesReceived,
    au.BadgesCount,
    phs.EditCount,
    phs.LastEditDate,
    phs.EditComments
FROM 
    TagStatistics ts
LEFT JOIN 
    ActiveUsers au ON au.PostsCreated > 0
LEFT JOIN 
    PostHistoryStatistics phs ON phs.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%' || ts.TagName || '%')
ORDER BY 
    ts.PostCount DESC, au.VotesReceived DESC;
