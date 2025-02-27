WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
PostVoteSummary AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
ClosedPostCounts AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(UB.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(UB.BadgeNames, 'No badges') AS UserBadgeNames,
    RP.RecentRank,
    RP.PostId,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostCreationDate,
    COALESCE(PVS.UpVotes, 0) AS PostUpVotes,
    COALESCE(PVS.DownVotes, 0) AS PostDownVotes,
    COALESCE(PVS.TotalVotes, 0) AS PostTotalVotes,
    COALESCE(CPC.CloseCount, 0) AS PostCloseCount,
    COALESCE(CPC.ReopenCount, 0) AS PostReopenCount
FROM 
    Users U
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    RecentPosts RP ON U.Id = RP.OwnerUserId AND RP.RecentRank = 1
LEFT JOIN 
    PostVoteSummary PVS ON RP.PostId = PVS.PostId
LEFT JOIN 
    ClosedPostCounts CPC ON RP.PostId = CPC.PostId
WHERE 
    U.Reputation > 1000 
    AND U.Location IS NOT NULL
ORDER BY 
    U.Reputation DESC, RP.RecentPostCreationDate DESC;
