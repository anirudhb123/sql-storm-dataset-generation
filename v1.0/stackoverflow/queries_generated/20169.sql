WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY COUNT(DISTINCT P.Id) DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, Reputation, PostCount, TotalBounties, Upvotes, Downvotes,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserActivity
    WHERE 
        PostCount > 5
),
RecentPostHistory AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS EditCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (4, 5, 6) THEN 1 END) AS TitleAndBodyEdits,
        MAX(PH.CreationDate) AS LatestEditDate
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.CreationDate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY 
        PH.UserId
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.PostCount,
    TU.TotalBounties,
    TU.Upvotes - TU.Downvotes AS NetVotes,
    COALESCE(RPH.EditCount, 0) AS EditCount,
    COALESCE(RPH.TitleAndBodyEdits, 0) AS TitleAndBodyEdits,
    CASE 
        WHEN RPH.LatestEditDate IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS UserStatus
FROM 
    TopUsers TU
LEFT JOIN 
    RecentPostHistory RPH ON TU.UserId = RPH.UserId
WHERE 
    (TU.Reputation > 1000 AND TU.PostCount > 10) OR 
    (RPH.EditCount > 5 AND NetVotes > 10)
ORDER BY 
    TU.ReputationRank, TU.NetVotes DESC;
