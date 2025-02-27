WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.Score > 0
        AND P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostVoteCounts AS (
    SELECT 
        P.Id AS PostId,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) AS VoteChanges
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN RP.PostRank <= 5 THEN 1 ELSE 0 END), 0) AS TopPostsCount,
        COALESCE(UB.BadgeCount, 0) AS TotalBadges,
        COALESCE(MAX(UB.HighestBadgeClass), 0) AS HighestBadgeClass,
        COALESCE(PVC.UpVotes, 0) AS TotalUpVotes,
        COALESCE(PVC.DownVotes, 0) AS TotalDownVotes,
        COALESCE(PVC.VoteChanges, 0) AS TotalVoteChanges
    FROM 
        Users U
    LEFT JOIN 
        RankedPosts RP ON U.Id = RP.OwnerUserId
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostVoteCounts PVC ON U.Id = PVC.UserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.TopPostsCount,
    U.TotalBadges,
    CASE 
        WHEN U.HighestBadgeClass = 1 THEN 'Gold Star Contributor'
        WHEN U.HighestBadgeClass = 2 THEN 'Silver Star Contributor'
        WHEN U.HighestBadgeClass = 3 THEN 'Bronze Star Contributor'
        ELSE 'No Badges'
    END AS BadgeTitle,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.TotalVoteChanges,
    CASE 
        WHEN U.TotalUpVotes > U.TotalDownVotes THEN 'Positive Influence'
        WHEN U.TotalUpVotes < U.TotalDownVotes THEN 'Negative Influence'
        ELSE 'Neutral Influence'
    END AS InfluenceRating
FROM 
    UserPostStats U
WHERE 
    U.TopPostsCount > 0
ORDER BY 
    U.TotalBadges DESC, U.TopPostsCount DESC
FETCH FIRST 10 ROWS ONLY;
