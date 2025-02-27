WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTagWikis,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostAggregates AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostLinks PL ON P.Id = PL.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalTagWikis,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.TotalBadges,
    P.PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    P.CommentCount,
    P.RelatedPostCount
FROM 
    UserStats U
JOIN 
    PostAggregates P ON P.PostId IN (
        SELECT PostId 
        FROM Posts 
        WHERE OwnerUserId = U.UserId 
        ORDER BY CreationDate DESC 
        LIMIT 10
    )
ORDER BY 
    U.Reputation DESC, P.Score DESC, U.DisplayName;
