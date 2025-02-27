WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(P.Score, 0)) AS AvgScore,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%' 
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalViews,
        AvgScore,
        CommentCount,
        VoteCount,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM 
        TagStats
),
UserStats AS (
    SELECT 
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViewsByUser,
        SUM(COALESCE(P.Score, 0)) AS TotalUserScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.DisplayName
),
TopUsers AS (
    SELECT 
        DisplayName,
        PostsCreated,
        TotalViewsByUser,
        TotalUserScore,
        ROW_NUMBER() OVER (ORDER BY TotalViewsByUser DESC) AS UserRank
    FROM 
        UserStats
)
SELECT 
    TT.TagName,
    TT.PostCount,
    TT.TotalViews,
    TT.AvgScore,
    TT.CommentCount,
    TT.VoteCount,
    TU.DisplayName AS TopUser,
    TU.PostsCreated,
    TU.TotalViewsByUser,
    TU.TotalUserScore
FROM 
    TopTags TT
LEFT JOIN 
    TopUsers TU ON TU.PostsCreated = TT.PostCount
WHERE 
    TT.Rank <= 10
ORDER BY 
    TT.Rank;
