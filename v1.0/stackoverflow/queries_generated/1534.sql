WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId    
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
TagStats AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostsCount,
        SUM(P.ViewCount) AS TotalViews,
        ROUND(AVG(P.Score), 2) AS AvgScore
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.Id, T.TagName
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(PH.Id) AS CloseCount
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    GROUP BY 
        P.Id
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.CreationDate,
    US.Upvotes,
    US.Downvotes,
    US.PostCount,
    TS.TagId,
    TS.TagName,
    TS.PostsCount,
    TS.TotalViews,
    TS.AvgScore,
    COALESCE(CP.CloseCount, 0) AS CloseCount
FROM 
    UserStats US
JOIN 
    TagStats TS ON US.PostCount > 0
LEFT JOIN 
    ClosedPosts CP ON CP.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = US.UserId)
WHERE 
    US.Reputation > 100
ORDER BY 
    US.Reputation DESC, TS.TotalViews DESC
LIMIT 50;
