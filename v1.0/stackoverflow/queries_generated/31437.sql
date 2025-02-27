WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.Name AS BadgeName,
        B.Class,
        B.Date,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY B.Date DESC) AS BadgeRank
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
), 
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(PH.CloseReasonTypesName, 'Not Closed') AS CloseReason,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT PostId, MIN(UserId) as ClosedByUserId, COUNT(*) AS CloseCount 
         FROM PostHistory PH
         JOIN CloseReasonTypes CRT ON PH.Comment::int = CRT.Id
         WHERE PH.PostHistoryTypeId = 10
         GROUP BY PostId
        ) AS PH ON P.Id = PH.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.OwnerUserId, P.Title, P.CreationDate, P.Score, P.ViewCount, PH.CloseReasonTypesName
), 
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.PostCount,
    UA.TotalScore,
    UA.TotalViews,
    UA.AvgScore,
    UB.BadgeName,
    UB.Class,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.CloseReason
FROM 
    UserActivity UA
LEFT JOIN 
    UserBadges UB ON UA.UserId = UB.UserId AND UB.BadgeRank = 1
LEFT JOIN 
    PostSummary PS ON UA.UserId = PS.OwnerUserId
WHERE 
    UA.TotalScore > (SELECT AVG(TotalScore) FROM UserActivity) -- Only include users with above-average scores
ORDER BY 
    UA.TotalViews DESC, 
    UB.Class ASC NULLS LAST;
