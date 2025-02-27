WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment,
        RANK() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Closed or Reopened posts
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalUpVotes - TotalDownVotes AS VoteBalance, 
        UserRank
    FROM 
        UserStats
    WHERE 
        UserRank <= 10
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.VoteBalance,
    CASE 
        WHEN RPH.PostId IS NULL THEN 'No Recent Activity' 
        ELSE CONCAT('Last Action: ', RPH.Comment, ' on ', TO_CHAR(RPH.CreationDate, 'YYYY-MM-DD HH24:MI:SS'))
    END AS RecentActivity,
    P.Title,
    P.Tags,
    P.CreationDate AS PostCreationDate
FROM 
    TopUsers TU
LEFT JOIN 
    RecentPostHistory RPH ON TU.UserId = RPH.UserId AND RPH.HistoryRank = 1
LEFT JOIN 
    Posts P ON RPH.PostId = P.Id
WHERE 
    P.CreationDate > NOW() - INTERVAL '30 days'
ORDER BY 
    TU.Reputation DESC, 
    TU.VoteBalance DESC;
