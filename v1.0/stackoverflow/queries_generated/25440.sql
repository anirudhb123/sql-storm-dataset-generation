WITH TagDetails AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount,
        STRING_AGG(DISTINCT p.Title, '; ') AS PostTitles,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id, t.TagName
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpvotesReceived,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS DownvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryCount AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    tg.TagId,
    tg.TagName,
    tg.PostCount,
    tg.PostTitles,
    tg.TotalViews,
    tg.TotalAnswers,
    ua.UserId,
    ua.DisplayName,
    ua.PostsCreated,
    ua.CommentsMade,
    ua.UpvotesReceived,
    ua.DownvotesReceived,
    ph.HistoryCount
FROM 
    TagDetails tg
JOIN 
    UserActivity ua ON ua.PostsCreated > 0
LEFT JOIN 
    PostHistoryCount ph ON ph.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%' || tg.TagName || '%')
ORDER BY 
    tg.TotalViews DESC, 
    ua.UpvotesReceived DESC;
