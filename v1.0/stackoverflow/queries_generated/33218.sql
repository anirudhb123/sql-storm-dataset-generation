WITH RECURSIVE UserPostCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        UserPostCounts 
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT ph.Comment, ', ') AS EditComments
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(tu.PostCount, 0) AS TotalPosts,
    COUNT(DISTINCT rp.PostId) AS RecentPostCount,
    COALESCE(pha.EditCount, 0) AS TotalEdits,
    pha.LastEditDate,
    pha.EditComments,
    CASE 
        WHEN tu.Rank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType,
    CASE 
        WHEN u.Location IS NOT NULL THEN u.Location
        ELSE 'Location Not Provided'
    END AS UserLocation
FROM 
    Users u
LEFT JOIN 
    TopUsers tu ON u.Id = tu.UserId
LEFT JOIN 
    RecentPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    PostHistoryAggregates pha ON rp.PostId = pha.PostId
GROUP BY 
    u.Id, tu.Rank, tu.PostCount, pha.LastEditDate, pha.EditComments
ORDER BY 
    TotalPosts DESC, RecentPostCount DESC;
