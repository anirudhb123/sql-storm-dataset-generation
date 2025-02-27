WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalComments
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
),
TopTags AS (
    SELECT 
        TagName,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS RN
    FROM 
        TagStats
)
SELECT 
    T.TagName,
    T.TotalViews,
    P.Title AS MostViewedPost,
    P.ViewCount AS PostViewCount
FROM 
    TopTags T
JOIN 
    Posts P ON P.Tags LIKE '%' || T.TagName || '%'
WHERE 
    T.RN <= 10 
ORDER BY 
    T.TotalViews DESC;

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounties,
        SUM(U.UpVotes) AS TotalUpVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id
)
SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.TotalComments,
    U.TotalBounties,
    U.TotalUpVotes,
    RANK() OVER (ORDER BY U.TotalUpVotes DESC) AS UserRank
FROM 
    UserStats U
WHERE 
    U.TotalPosts > 0
ORDER BY 
    U.TotalUpVotes DESC
LIMIT 10;

WITH PostVoteStats AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    GROUP BY 
        P.Id
)
SELECT 
    P.Title,
    P.CreationDate,
    P.ViewCount,
    PVS.TotalUpVotes,
    PVS.TotalDownVotes,
    (PVS.TotalUpVotes - PVS.TotalDownVotes) AS NetScore
FROM 
    Posts P
JOIN 
    PostVoteStats PVS ON P.Id = PVS.PostId
WHERE 
    P.PostTypeId = 1
ORDER BY 
    NetScore DESC
LIMIT 10;
