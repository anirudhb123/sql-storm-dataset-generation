WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AvgPostScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS TagPostCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON t.Id = ANY(string_to_array(pt.Tags, '><')::int[])
    GROUP BY 
        t.TagName
    ORDER BY 
        TagPostCount DESC
    LIMIT 10
),
PostHistoryStats AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS TotalEdits,
        COUNT(DISTINCT ph.PostId) AS UniquePostsEdited
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (24, 10) -- Suggested Edits and Post Closed
    GROUP BY 
        ph.UserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.AvgPostScore,
    ups.TotalViews,
    COALESCE(pqs.TotalEdits, 0) AS TotalEdits,
    COALESCE(pqs.UniquePostsEdited, 0) AS UniquePostsEdited,
    STRING_AGG(tt.TagName, ', ') AS TopTags
FROM 
    UserPostStats ups
LEFT JOIN 
    PostHistoryStats pqs ON ups.UserId = pqs.UserId
LEFT JOIN 
    TopTags tt ON true
GROUP BY 
    ups.UserId, ups.DisplayName, ups.TotalPosts, ups.TotalQuestions, ups.TotalAnswers, ups.AvgPostScore, ups.TotalViews, pqs.TotalEdits, pqs.UniquePostsEdited
ORDER BY 
    ups.TotalPosts DESC, ups.DisplayName
LIMIT 20;
