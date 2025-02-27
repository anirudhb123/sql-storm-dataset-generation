WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId = 8 THEN V.BountyAmount ELSE 0 END) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        P.Tags,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT 
    U.DisplayName AS UserName,
    UPS.UpVotes,
    UPS.DownVotes,
    UPS.TotalBounty,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    COALESCE(PHT.Name, 'No History') AS LastPostHistory,
    CASE 
        WHEN RP.RecentPostRank = 1 THEN 'Most Recent Post'
        ELSE NULL
    END AS PostStatus
FROM 
    UserVoteSummary UPS
LEFT JOIN 
    RecentPosts RP ON UPS.UserId = RP.OwnerUserId
LEFT JOIN 
    PostHistory PH ON RP.PostId = PH.PostId
LEFT JOIN 
    PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
WHERE 
    UPS.UpVotes - UPS.DownVotes > 5
ORDER BY 
    UPS.TotalBounty DESC, RP.Score DESC
LIMIT 50;
