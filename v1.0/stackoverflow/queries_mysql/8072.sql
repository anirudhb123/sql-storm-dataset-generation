
WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = U.Id) AS PostCount,
        (SELECT COUNT(*) FROM Comments C WHERE C.UserId = U.Id) AS CommentCount,
        @row_number := @row_number + 1 AS UserRank
    FROM 
        Users U, (SELECT @row_number := 0) r
    ORDER BY 
        U.Reputation DESC
),
PopularTags AS (
    SELECT 
        T.TagName, 
        T.Count,
        @row_number_tags := @row_number_tags + 1 AS TagRank
    FROM 
        Tags T, (SELECT @row_number_tags := 0) rt
    ORDER BY 
        T.Count DESC
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        PT.Name AS PostType,
        COUNT(C.Id) AS TotalComments,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts P
    LEFT JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.Score, PT.Name
),
ClosedPostStats AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        COUNT(DISTINCT PH.UserId) AS UserCloseCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.PostId
)
SELECT 
    U.UserRank, 
    U.DisplayName, 
    U.Reputation, 
    U.PostCount, 
    U.CommentCount,
    T.TagName,
    PS.PostId,
    PS.Title,
    PS.ViewCount,
    PS.Score,
    PS.TotalComments,
    PS.TotalBounty,
    COALESCE(CPS.CloseCount, 0) AS CloseCount,
    COALESCE(CPS.UserCloseCount, 0) AS UserCloseCount
FROM 
    RankedUsers U
JOIN 
    PopularTags T ON U.UserRank <= 5 
JOIN 
    PostStats PS ON U.UserId = PS.PostId 
LEFT JOIN 
    ClosedPostStats CPS ON PS.PostId = CPS.PostId
WHERE 
    T.Count > 100 
ORDER BY 
    U.Reputation DESC, PS.ViewCount DESC;
