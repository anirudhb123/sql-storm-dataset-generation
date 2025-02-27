WITH TagStatistics AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(p.FavoriteCount, 0)) AS TotalFavorites,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON t.TagName = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
    GROUP BY 
        t.Id, t.TagName
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(v.VoteTypeId = 2, 0)::int) AS TotalUpvotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)::int) AS TotalDownvotes,
        AVG(COALESCE(u.Reputation, 0)) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS EditCount,
        COUNT(DISTINCT ph.UserId) AS UniqueEditors
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.TotalAnswers,
    ts.TotalFavorites,
    ts.AverageScore,
    ua.DisplayName AS ActiveUser,
    ua.PostsCreated,
    ua.TotalUpvotes,
    ua.TotalDownvotes,
    ua.AverageReputation,
    phs.EditCount,
    phs.UniqueEditors
FROM 
    TagStatistics ts
JOIN 
    UserActivity ua ON ua.PostsCreated > 0
JOIN 
    PostHistorySummary phs ON phs.PostId = (SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' || ts.TagName || '%')
ORDER BY 
    ts.PostCount DESC, ua.TotalUpvotes DESC
LIMIT 10;
