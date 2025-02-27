WITH UserPostCount AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(p.Id) AS TotalPosts, 
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), RankedUsers AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN TotalPosts > 0 THEN 1 ELSE 0 END ORDER BY AvgScore DESC) AS Rank
    FROM 
        UserPostCount
), TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostsWithTag,
        SUM(CASE WHEN p.AnswerCount > 0 THEN 1 ELSE 0 END) AS QuestionsWithAnswers
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
), RecentPostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    ru.UserId,
    ru.DisplayName,
    ru.TotalPosts,
    ru.PositivePosts,
    ru.NegativePosts,
    ru.AvgScore,
    tu.TagName,
    tu.PostsWithTag,
    tu.QuestionsWithAnswers,
    rph.PostId,
    rph.Title,
    rph.PostHistoryTypeId,
    rph.CreationDate AS HistoryDate,
    rph.UserDisplayName AS HistoryEditor
FROM 
    RankedUsers ru
LEFT OUTER JOIN 
    TagUsage tu ON ru.TotalPosts > 0
LEFT JOIN 
    RecentPostHistory rph ON rph.HistoryRank = 1
WHERE 
    (ru.TotalPosts > 5 OR ru.AvgScore IS NULL)
    AND (ru.PositivePosts IS NOT NULL OR ru.NegativePosts < 3)
ORDER BY 
    ru.Rank, ru.AvgScore DESC, tu.PostsWithTag DESC
LIMIT 100;
