WITH TagCounts AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount
    FROM 
        Posts
    JOIN 
        LATERAL string_to_array(substring(Tags, 2, length(Tags) - 2), '><') AS Tags ON TRUE
    GROUP BY 
        Tags.TagName
),
UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 9 -- BountyClose
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS Author,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(COALESCE(V.Score, 0)) AS TotalScore,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 'Yes' 
            ELSE 'No' 
        END AS HasAcceptedAnswer
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId 
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.Id, P.Title, U.DisplayName, P.AcceptedAnswerId
)
SELECT 
    TS.TagName,
    TC.PostCount,
    US.UserId,
    US.DisplayName,
    US.TotalBounty,
    US.TotalViews,
    PS.PostId,
    PS.Title,
    PS.Author,
    PS.CommentCount,
    PS.TotalScore,
    PS.HasAcceptedAnswer
FROM 
    TagCounts TC
JOIN 
    PostStatistics PS ON PS.Title ILIKE '%' || TC.TagName || '%'
JOIN 
    UserScore US ON PS.Author = US.DisplayName
ORDER BY 
    TC.PostCount DESC, US.TotalBounty DESC, PS.TotalScore DESC
LIMIT 100;
