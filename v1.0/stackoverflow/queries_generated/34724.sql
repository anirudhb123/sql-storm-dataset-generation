WITH RecursivePostHierarchy AS (
    SELECT 
        Id, 
        Title, 
        ParentId, 
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id, 
        p.Title, 
        p.ParentId, 
        Ph.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy Ph ON p.ParentId = Ph.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE 
            WHEN p.PostTypeId = 1 THEN 1 
            ELSE 0 
        END) AS QuestionCount,
        SUM(CASE 
            WHEN p.PostTypeId = 2 THEN 1 
            ELSE 0 
        END) AS AnswerCount,
        AVG(v.BountyAmount) AS AvgBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId, 
        PHT.Name AS HistoryType, 
        ph.CreationDate,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    up.DisplayName AS OwnerDisplayName,
    ua.PostCount,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.AvgBounty,
    COALESCE(rp.Id, 'No Parent') AS ParentPostId,
    COALESCE(rp.Title, 'N/A') AS ParentPostTitle,
    recent.HistoryType,
    recent.CreationDate AS HistoryDate,
    recent.UserDisplayName AS HistoryUser
FROM 
    Posts p
LEFT JOIN 
    Users up ON p.OwnerUserId = up.Id
LEFT JOIN 
    RecursivePostHierarchy rp ON p.ParentId = rp.Id
LEFT JOIN 
    UserActivity ua ON up.Id = ua.UserId
LEFT JOIN 
    RecentPostHistory recent ON p.Id = recent.PostId AND recent.rn = 1
WHERE 
    p.ViewCount > 100 AND 
    (p.Tags LIKE '%SQL%' OR p.Tags LIKE '%database%') AND 
    (p.ClosedDate IS NULL OR p.ClosedDate > NOW() - INTERVAL '30 days')
ORDER BY 
    p.CreationDate DESC
LIMIT 50;
