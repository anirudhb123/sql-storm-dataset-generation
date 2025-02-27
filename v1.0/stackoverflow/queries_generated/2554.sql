WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation * (SELECT COUNT(*) FROM Badges WHERE UserId = Users.Id) AS TotalScore,
        COUNT(Posts.Id) AS PostCount
    FROM 
        Users 
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id, Reputation
), 
TopUsers AS (
    SELECT 
        UserId, 
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserReputation
    WHERE 
        TotalScore > (SELECT AVG(TotalScore) FROM UserReputation)
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        a.Body,
        p.Score AS PostScore,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
)

SELECT 
    tu.UserId, 
    tu.Rank,
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.CreationDate,
    pd.Body,
    pd.PostScore,
    pd.OwnerDisplayName,
    pd.CommentCount
FROM 
    TopUsers tu
INNER JOIN 
    PostDetails pd ON tu.UserId = pd.OwnerDisplayName 
WHERE 
    tu.Rank <= 10 AND 
    pd.RecentPostRank = 1
ORDER BY 
    tu.Rank, pd.ViewCount DESC;

-- Additionally evaluate how many posts have been closed versus opened in the last month
SELECT 
    CASE WHEN StatusHistory IS NULL THEN 'No History' ELSE 'Has History' END AS HistoryStatus,
    COUNT(*) AS PostCount
FROM (
    SELECT 
        p.Id AS PostId,
        CASE 
            WHEN EXISTS (SELECT 1 FROM PostHistory ph WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId = 10 AND ph.CreationDate >= CURRENT_DATE - INTERVAL '30 days') 
            THEN 'Closed' 
            ELSE NULL 
        END AS StatusHistory
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
) AS StatusTable
GROUP BY 
    StatusHistory;
