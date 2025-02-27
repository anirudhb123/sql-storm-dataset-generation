WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS TotalPositiveScorePosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), 
TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS UsageCount,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    GROUP BY 
        t.Id, t.TagName
), 
PostHistoryAggregates AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS EditCount,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalTagWikis,
    ups.TotalPositiveScorePosts,
    ts.TagId,
    ts.TagName,
    ts.UsageCount,
    ts.TotalComments,
    pha.EditCount,
    pha.FirstEditDate,
    pha.LastEditDate
FROM 
    UserPostStats ups
JOIN 
    TagStats ts ON ts.UsageCount > 0
JOIN 
    PostHistoryAggregates pha ON pha.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ups.UserId)
WHERE 
    ups.TotalPosts > 10
ORDER BY 
    ups.TotalPosts DESC, ts.UsageCount DESC, ups.UserId;
