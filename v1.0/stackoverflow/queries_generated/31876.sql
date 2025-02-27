WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2022-01-01' -- Filter for relevant posts
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= '2022-01-01'
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 5 -- Consider users with more than 5 posts
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalViews,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS ActiveRank
    FROM 
        TopUsers
),
PostHistoryCounts AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Focus on Title, Body, Tags edits
    GROUP BY 
        ph.PostId
)
SELECT 
    au.DisplayName,
    au.TotalViews,
    au.PostCount,
    CASE 
        WHEN php.EditCount IS NULL THEN 0 
        ELSE php.EditCount 
    END AS TotalEdits,
    COALESCE(lp.LinkCount, 0) AS LinkCount,
    rp.Rank
FROM 
    ActiveUsers au
LEFT JOIN 
    PostHistoryCounts php ON au.UserId = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = php.PostId)
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(L.Id) AS LinkCount
    FROM 
        PostLinks L
    GROUP BY 
        PostId
) lp ON lp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = au.UserId)
LEFT JOIN 
    RankedPosts rp ON rp.OwnerUserId = au.UserId
WHERE 
    au.ActiveRank <= 10 -- Limit to top 10 active users based on views
ORDER BY 
    au.TotalViews DESC, au.DisplayName;
