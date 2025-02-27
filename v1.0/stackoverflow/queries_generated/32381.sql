WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(p.ParentId, p.Id) AS RootPostId,
        p.OwnerUserId,
        p.CreationDate,
        p.LastActivityDate,
        p.Title,
        p.Score,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Considering only questions as root for the hierarchy

    UNION ALL

    SELECT 
        a.Id AS PostId,
        r.RootPostId,
        a.OwnerUserId,
        a.CreationDate,
        a.LastActivityDate,
        a.Title,
        a.Score,
        r.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePostHierarchy r ON r.PostId = a.ParentId
    WHERE 
        a.PostTypeId = 2  -- Only answers
),

UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(p.ViewCount) AS TotalViews,
        MAX(p.LastActivityDate) AS LastActiveDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),

PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),

TopUsersByActivity AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        ROW_NUMBER() OVER (ORDER BY SUM(p.Score) DESC) AS Rank
    FROM 
        UserPostStats u
    JOIN 
        Posts p ON u.UserId = p.OwnerUserId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '30 days'  -- Last 30 days
    GROUP BY 
        u.UserId, u.DisplayName
)

SELECT 
    p.Title,
    p.Score AS PostScore,
    COALESCE(up.TotalPosts, 0) AS UserTotalPosts,
    COALESCE(up.PositivePosts, 0) AS UserPositivePosts,
    COALESCE(up.NegativePosts, 0) AS UserNegativePosts,
    COALESCE(up.TotalViews, 0) AS UserTotalViews,
    RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank,
    ROW_NUMBER() OVER (PARTITION BY r.Level ORDER BY p.LastActivityDate DESC) AS ActivityRankByLevel,
    ph.HistoryCount AS EditHistoryCount,
    ph.LastChangeDate AS LastEditDate
FROM 
    Posts p
LEFT JOIN 
    UserPostStats up ON p.OwnerUserId = up.UserId
LEFT JOIN 
    PostHistoryAggregates ph ON p.Id = ph.PostId
LEFT JOIN 
    RecursivePostHierarchy r ON p.Id = r.PostId
WHERE 
    p.CreationDate > NOW() - INTERVAL '1 year'  -- Posts created in the last year
AND 
    (p.Tags LIKE '%SQL%' OR p.Tags LIKE '%Database%')  -- Filter on tags
ORDER BY 
    p.Score DESC, UserTotalPosts DESC;
