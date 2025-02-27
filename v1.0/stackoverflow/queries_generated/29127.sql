WITH TagUsage AS (
    SELECT 
        tr.TagName, 
        COUNT(p.Id) AS PostCount, 
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount
    FROM 
        Tags tr
    LEFT JOIN 
        Posts p ON tr.Id = ANY(string_to_array(p.Tags, ''))::int[] -- Assuming Tags stored as a comma-separated string of integers
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        tr.Count > 0
    GROUP BY 
        tr.TagName
),
User Engagement AS (
    SELECT 
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.DisplayName
),
TagPerformance AS (
    SELECT 
        t.TagName,
        tu.PostCount,
        tu.CommentCount,
        tu.AcceptedAnswerCount,
        COALESCE(SUM(ue.TotalScore), 0) AS ScoreByUsers,
        COALESCE(SUM(ue.TotalViews), 0) AS ViewsByUsers
    FROM 
        TagUsage tu
    JOIN 
        Tags t ON t.TagName = tu.TagName
    LEFT JOIN 
        UserEngagement ue ON ue.TotalPosts > 0
    GROUP BY 
        t.TagName, tu.PostCount, tu.CommentCount, tu.AcceptedAnswerCount
)
SELECT 
    p.TagName AS Tag,
    p.PostCount AS Posts,
    p.CommentCount AS Comments,
    p.AcceptedAnswerCount AS AcceptedAnswers,
    p.ScoreByUsers AS TotalScoreByUsers,
    p.ViewsByUsers AS TotalViewsByUsers,
    (CASE 
        WHEN p.PostCount > 0 THEN ROUND((p.ScoreByUsers::numeric / p.PostCount), 2)
        ELSE 0 
    END) AS AvgScorePerPost,
    (CASE 
        WHEN p.ViewsByUsers > 0 THEN ROUND((p.ViewsByUsers::numeric / NULLIF(p.PostCount, 0)), 2)
        ELSE 0 
    END) AS AvgViewsPerPost
FROM 
    TagPerformance p
ORDER BY 
    p.PostCount DESC, 
    p.ViewsByUsers DESC;
