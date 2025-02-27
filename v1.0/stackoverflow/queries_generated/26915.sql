WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        t.TagName
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT a.Id) AS AnswersGiven,
        SUM(COALESCE(v.DownModCount, 0)) AS TotalDownvotes,
        SUM(COALESCE(v.UpModCount, 0)) AS TotalUpvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    LEFT JOIN 
        (SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpModCount,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownModCount
        FROM 
            Votes
        GROUP BY 
            PostId) v ON p.Id = v.PostId
    WHERE 
        u.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(ph.Id) AS EditCount,
        STRING_AGG(DISTINCT ph.UserDisplayName) AS Editors,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, Tags
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.AvgUserReputation,
    ue.DisplayName AS EngagedUser,
    ue.QuestionsAsked,
    ue.AnswersGiven,
    ue.TotalDownvotes,
    ue.TotalUpvotes,
    phi.Title AS LatestEditedPost,
    phi.EditCount,
    phi.Editors,
    phi.LastEditDate
FROM 
    TagStatistics ts
LEFT JOIN 
    UserEngagement ue ON true -- Cross join to get tag stats against each user, modify condition based on actual requirement 
LEFT JOIN 
    PostHistoryInfo phi ON ts.TagName IN (SELECT unnest(string_to_array(phi.Title, ' ')))/intersecting tags
ORDER BY 
    ts.TotalViews DESC, ue.TotalUpvotes DESC;
