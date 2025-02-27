WITH RecursivePostCTE AS (
    SELECT 
        Id AS PostId,
        Title,
        ViewCount,
        OwnerUserId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Selecting questions only

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.OwnerUserId,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE rp ON p.ParentId = rp.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.Reputation) OVER (PARTITION BY u.Id) AS TotalReputation,
        ROW_NUMBER() OVER (ORDER BY SUM(u.Reputation) DESC) AS Rank
    FROM 
        Users u
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10) -- Edit Title, Edit Body, Edit Tags, Post Closed
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    ur.DisplayName,
    ur.TotalReputation,
    COALESCE(phs.HistoryCount, 0) AS HistoryCount,
    phs.LastEditDate,
    CASE 
        WHEN ur.Rank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserStatus
FROM 
    RecursivePostCTE rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    PostHistorySummary phs ON rp.PostId = phs.PostId
WHERE 
    rp.ViewCount > (SELECT AVG(ViewCount) FROM Posts) -- Filter by posts with above-average views
    AND ur.TotalReputation > 100 -- Only users with reputation greater than 100
ORDER BY 
    rp.ViewCount DESC, 
    phs.LastEditDate DESC;
