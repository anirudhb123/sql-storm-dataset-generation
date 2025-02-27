WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(CASE WHEN p.ViewCount > 0 THEN p.ViewCount ELSE NULL END) AS AvgViewCount
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT
        ph.UserId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS TotalCloseVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (11, 13) THEN 1 END) AS TotalReopenUndeleteVotes,
        MAX(ph.CreationDate) AS LastActionDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.UserId
),
CombinedStats AS (
    SELECT
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalQuestions,
        ups.TotalAnswers,
        ups.AvgViewCount,
        COALESCE(pht.TotalCloseVotes, 0) AS TotalCloseVotes,
        COALESCE(pht.TotalReopenUndeleteVotes, 0) AS TotalReopenUndeleteVotes,
        pht.LastActionDate
    FROM 
        UserPostStats ups
        LEFT JOIN PostHistoryStats pht ON ups.UserId = pht.UserId
)
SELECT 
    cs.DisplayName,
    cs.TotalPosts,
    cs.TotalQuestions,
    cs.TotalAnswers,
    cs.AvgViewCount,
    cs.TotalCloseVotes,
    cs.TotalReopenUndeleteVotes,
    cs.LastActionDate,
    CASE 
        WHEN cs.TotalQuestions > 100 THEN 'Expert'
        WHEN cs.TotalQuestions BETWEEN 50 AND 100 THEN 'Intermediate'
        ELSE 'Novice'
    END AS UserLevel,
    CASE 
        WHEN cs.AvgViewCount IS NULL THEN 'No Views'
        WHEN cs.AvgViewCount > 1000 THEN 'High Engagement'
        WHEN cs.AvgViewCount BETWEEN 100 AND 1000 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    (SELECT STRING_AGG(b.Name, ', ') 
     FROM Badges b 
     WHERE b.UserId = cs.UserId 
     AND b.Date >= NOW() - INTERVAL '1 year' 
     GROUP BY b.UserId) AS RecentBadges
FROM 
    CombinedStats cs
WHERE 
    cs.TotalPosts > 0
ORDER BY 
    cs.TotalPosts DESC,
    cs.DisplayName ASC
LIMIT 50;

WITH Recursive TagHierarchy AS (
    SELECT 
        Id, 
        TagName, 
        WikiPostId, 
        0 AS Level
    FROM 
        Tags
    WHERE 
        IsModeratorOnly = 1
    UNION ALL
    SELECT 
        t.Id, 
        t.TagName, 
        t.WikiPostId, 
        th.Level + 1
    FROM 
        Tags t
        INNER JOIN TagHierarchy th ON t.ExcerptPostId = th.Id
)
SELECT 
    th.TagName,
    COUNT(DISTINCT p.Id) AS PostCount,
    AVG(COALESCE(p.ViewCount, 0)) AS AvgViewCount,
    MAX(th.Level) AS MaxLevel
FROM 
    TagHierarchy th
    LEFT JOIN Posts p ON th.Id = substring(p.Tags from '[^<>]*')::int  -- assuming Tags contains IDs
GROUP BY 
    th.TagName
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    PostCount DESC;

SELECT 
    pt.Name AS PostTypeName, 
    COUNT(*) AS PostCount, 
    COALESCE(NULLIF(AVG(CommentsCount), 0), 0) AS AvgComments,
    COUNT(CASE WHEN cp.Tags IS NULL THEN 1 END) AS TagsAbsent
FROM 
    Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentsCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) cp ON p.Id = cp.PostId
GROUP BY 
    pt.Name
HAVING 
    COUNT(*) >= 10
ORDER BY 
    PostCount DESC;

