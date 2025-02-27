WITH UserRankings AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(V.VoteTypeId = 2) AS TotalUpvotes,
        SUM(V.VoteTypeId = 3) AS TotalDownvotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        RANK() OVER (ORDER BY SUM(V.VoteTypeId = 2) - SUM(V.VoteTypeId = 3) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id AND V.PostId IN (SELECT Id FROM Posts)
    GROUP BY 
        U.Id, U.DisplayName
),
TopPostTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%' )
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerName,
        P.Tags,
        PH.Comment AS LastEditComment
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId 
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    UR.DisplayName,
    UR.TotalUpvotes,
    UR.TotalDownvotes,
    UR.TotalPosts,
    UR.TotalComments,
    TPT.TagName AS PopularTag,
    PD.Title,
    PD.Body,
    PD.CreationDate,
    PD.ViewCount,
    PD.Score,
    PD.LastEditComment
FROM 
    UserRankings UR
JOIN 
    TopPostTags TPT ON UR.TotalPosts > 5
JOIN  
    PostDetails PD ON PD.PostId IN (SELECT PostId FROM Votes V WHERE V.UserId = UR.UserId)
ORDER BY 
    UR.UserRank, TPT.PostCount DESC, PD.Score DESC;
