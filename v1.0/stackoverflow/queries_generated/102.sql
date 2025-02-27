WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AverageScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        UB.UserId,
        UB.DisplayName,
        COALESCE(PS.TotalPosts, 0) AS TotalPosts,
        COALESCE(UB.TotalBadges, 0) AS TotalBadges,
        COALESCE(PS.AverageScore, 0) AS AverageScore
    FROM 
        UserBadges UB
    LEFT JOIN 
        PostStats PS ON UB.UserId = PS.OwnerUserId
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalBadges,
    TU.AverageScore,
    RANK() OVER (ORDER BY TU.TotalPosts DESC, TU.TotalBadges DESC, TU.AverageScore DESC) AS Rank
FROM 
    TopUsers TU
WHERE 
    TU.TotalPosts > 0
ORDER BY 
    Rank
LIMIT 10;

WITH RecentPostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount,
        MAX(C.CreationDate) AS LastCommentDate
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
CommentedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        COALESCE(RPC.CommentCount, 0) AS CommentCount,
        RPC.LastCommentDate
    FROM 
        Posts P
    LEFT JOIN 
        RecentPostComments RPC ON P.Id = RPC.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    CP.Title,
    CP.CommentCount,
    CASE 
        WHEN CP.CommentCount = 0 THEN 'No Comments Yet'
        ELSE 'Comments Available'
    END AS CommentStatus
FROM 
    CommentedPosts CP
WHERE 
    CP.CommentCount > 0
ORDER BY 
    CP.LastCommentDate DESC;

SELECT 
    P.Title,
    P.ViewCount,
    COALESCE(CM.CommentCount, 0) AS TotalComments
FROM 
    Posts P
LEFT JOIN (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
) CM ON P.Id = CM.PostId
WHERE 
    (P.ViewCount < 100 AND CM.CommentCount IS NULL)
    OR (P.ViewCount >= 100 AND CM.CommentCount >= 5)
ORDER BY 
    P.ViewCount DESC;

SELECT 
    PT.Name AS PostType,
    COUNT(P.Id) AS NumberOfPosts,
    AVG(V.BountyAmount) AS AverageBounty
FROM 
    PostTypes PT
LEFT JOIN 
    Posts P ON P.PostTypeId = PT.Id
LEFT JOIN 
    Votes V ON V.PostId = P.Id AND V.VoteTypeId = 8 -- BountyStart
GROUP BY 
    PT.Name
HAVING 
    AVG(V.BountyAmount) IS NOT NULL
ORDER BY 
    NumberOfPosts DESC;

SELECT 
    PT.Name AS PostType,
    COUNT(P.Id) AS PostCount,
    SUM(P.Score) AS TotalScore,
    AVG(P.Score) AS AverageScore
FROM 
    PostTypes PT
JOIN 
    Posts P ON P.PostTypeId = PT.Id
WHERE 
    P.CreationDate >= DATEADD(YEAR, -1, GETDATE())
GROUP BY 
    PT.Name
HAVING 
    SUM(P.Score) > 0
ORDER BY 
    TotalScore DESC;
