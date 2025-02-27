WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS EditTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
TopUsers AS (
    SELECT 
        UserId, 
        Reputation, 
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStatistics
    WHERE 
        Reputation > 1000
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        ph.LastEditDate,
        ph.EditCount,
        U.DisplayName AS OwnerName
    FROM 
        Posts p
    LEFT JOIN 
        PostHistoryAggregates ph ON p.Id = ph.PostId
    JOIN 
        Users U ON p.OwnerUserId = U.Id
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.LastEditDate,
    pd.EditCount,
    tu.DisplayName AS TopUser,
    tu.Rank,
    CASE 
        WHEN pd.EditCount > 3 THEN 'Frequently Edited'
        ELSE 'Rarely Edited'
    END AS EditFrequency,
    COALESCE(u.Reputation, 0) AS UserReputation,
    COALESCE(u.TotalPosts, 0) AS UserTotalPosts,
    COALESCE(u.TotalComments, 0) AS UserTotalComments,
    COALESCE(u.TotalBounty, 0) AS UserTotalBounties
FROM 
    PostDetails pd
LEFT JOIN 
    UserStatistics u ON pd.OwnerName = u.DisplayName
LEFT JOIN 
    TopUsers tu ON u.Id = tu.UserId
WHERE 
    pd.ViewCount > 100
ORDER BY 
    pd.ViewCount DESC, tu.Rank
LIMIT 10;
