WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
PostDetails AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate AS PostCreationDate, 
        pt.Name AS PostType, 
        COALESCE(CAST(p.Body AS TEXT), 'No Content') AS BodyContent,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(ROUND((EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)) / 86400)::numeric, 2), 0) AS AgeInDays,
        COALESCE(p.ViewCount, 0) AS Views
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
),
UserPosts AS (
    SELECT 
        pu.UserId, 
        COUNT(DISTINCT pu.PostId) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount
    FROM 
        Posts p
    INNER JOIN 
        Posts pu ON p.OwnerUserId = pu.OwnerUserId
    GROUP BY 
        pu.UserId
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId, 
        COUNT(ph.Id) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        ph.PostId
),
RecentPosts AS (
    SELECT 
        pd.*,
        phc.HistoryCount,
        CASE 
            WHEN phc.HistoryCount IS NULL THEN 'New'
            ELSE 'Edited/Active'
        END AS PostStatus
    FROM 
        PostDetails pd
    LEFT JOIN 
        PostHistoryCounts phc ON pd.PostId = phc.PostId
    WHERE 
        pd.PostCreationDate >= NOW() - INTERVAL '7 days'
)
SELECT 
    ru.DisplayName AS UserName,
    ru.UserRank,
    COUNT(DISTINCT rp.PostId) AS RecentPostsCount,
    SUM(rp.Views) AS TotalViews,
    AVG(rp.AgeInDays) AS AveragePostAge,
    SUM(COALESCE(b.Class, 0) * CASE 
            WHEN rp.PostType = 'Question' THEN 3
            WHEN rp.PostType = 'Answer' THEN 2
            ELSE 1 
        END) AS WeightedBadgeScore,
    STRING_AGG(DISTINCT CONCAT('Post Title: ', rp.Title, ' | Status: ', rp.PostStatus), '; ') AS RecentPostDetails
FROM 
    RankedUsers ru
LEFT JOIN 
    RecentPosts rp ON ru.UserId = rp.OwnerDisplayName
LEFT JOIN 
    Badges b ON ru.UserId = b.UserId
WHERE 
    ru.UserRank <= 100
GROUP BY 
    ru.DisplayName, 
    ru.UserRank
HAVING 
    COUNT(DISTINCT rp.PostId) > 0
ORDER BY 
    ru.UserRank;
