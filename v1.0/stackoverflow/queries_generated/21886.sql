WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        NTILE(5) OVER (ORDER BY U.Reputation DESC) AS ReputationTier,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(VoteTypeId = 2) AS UpVotes,
        SUM(VoteTypeId = 3) AS DownVotes,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosureCount,
        COALESCE(SUM(P.ViewCount), 0) AS TotalViewCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory PH ON PH.UserId = U.Id
    GROUP BY 
        U.Id
),
PostClosureReasons AS (
    SELECT 
        P.Id AS PostId, 
        P.Title,
        P.OwnerUserId, 
        PH.Comment AS ClosureReason,
        PH.CreationDate AS ClosureDate,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS ClosureRank
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON PH.PostId = P.Id AND PH.PostHistoryTypeId = 10
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.ReputationTier,
    US.BadgeCount,
    US.UpVotes,
    US.DownVotes,
    COALESCE(PR.ClosureReason, 'No Closure') AS ClosureReason,
    US.TotalViewCount,
    CASE 
        WHEN US.TotalViewCount = 0 THEN 'No Views'
        WHEN US.TotalViewCount > 1000 THEN 'Popular User'
        ELSE 'Regular User'
    END AS UserCategory
FROM 
    UserStats US
LEFT JOIN 
    PostClosureReasons PR ON PR.OwnerUserId = US.UserId AND PR.ClosureRank = 1
WHERE 
    US.ReputationTier IN (2, 3)  -- Considering medium to high reputation users
ORDER BY 
    US.Reputation DESC, US.BadgeCount DESC;
