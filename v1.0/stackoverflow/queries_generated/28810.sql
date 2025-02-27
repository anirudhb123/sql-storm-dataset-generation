WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(B.Class, 0)) AS TotalBadges,
        AVG(U.Reputation) AS AverageReputation
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
),
PostsWithHistory AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS EditRank,
        PH.Comment AS EditComment,
        PH.CreationDate AS EditDate
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.PostTypeId = 1 -- only questions
)
SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.TotalComments,
    U.TotalScore,
    U.TotalBadges,
    U.AverageReputation,
    TT.TagName,
    PH.PostId,
    PH.Title,
    PH.EditComment,
    PH.EditDate
FROM 
    UserStats U
JOIN 
    TopTags TT ON TT.PostCount > 5 -- Considering most used tags
JOIN 
    PostsWithHistory PH ON PH.EditRank = 1 -- Only the latest edit per post
ORDER BY 
    U.TotalScore DESC, U.TotalPosts DESC;
