WITH RECURSIVE UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(PH.CreationDate, P.CreationDate) AS LastModified,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY COALESCE(PH.CreationDate, P.CreationDate) DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5)
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '30 days'
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        COUNT(DISTINCT p.PostId) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        UserStatistics us
    JOIN 
        Posts p ON us.UserId = p.OwnerUserId
    GROUP BY 
        us.UserId, us.DisplayName, us.Reputation
    HAVING 
        SUM(p.Score) > 50
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.TotalScore,
    json_agg(rp.Title) AS RecentPostTitles,
    SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts
FROM 
    TopUsers tu
JOIN 
    RecentPosts rp ON tu.UserId = rp.OwnerUserId
JOIN 
    Posts p ON rp.PostId = p.Id
GROUP BY 
    tu.UserId, tu.DisplayName, tu.Reputation, tu.PostCount, tu.TotalScore
ORDER BY 
    tu.TotalScore DESC, tu.Reputation ASC
LIMIT 10;
