WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId IN (2, 4) THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COALESCE(SUM(B.Class), 0) AS TotalBadges,
        COALESCE(SUM(DISTINCT PH.PostId), 0) AS TotalPostHistoryChanges
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN PostHistory PH ON U.Id = PH.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        (SELECT COUNT(*) FROM Comments WHERE PostId = P.Id) AS TotalComments
    FROM Posts P
),
TopEngagedUsers AS (
    SELECT 
        UE.UserId,
        UE.DisplayName,
        UE.TotalUpvotes,
        UE.TotalDownvotes,
        UE.TotalComments,
        UE.TotalPosts,
        UE.TotalBadges,
        RANK() OVER (ORDER BY (UE.TotalUpvotes - UE.TotalDownvotes) DESC) AS EngagementRank
    FROM UserEngagement UE
    WHERE UE.TotalPosts > 0
)
SELECT 
    TE.DisplayName,
    TE.TotalPosts,
    TE.TotalUpvotes,
    TE.TotalDownvotes,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.TotalComments
FROM TopEngagedUsers TE
JOIN PostStatistics PS ON TE.UserId = PS.OwnerUserId
WHERE TE.EngagementRank <= 10
ORDER BY TE.EngagementRank, PS.ViewCount DESC;
