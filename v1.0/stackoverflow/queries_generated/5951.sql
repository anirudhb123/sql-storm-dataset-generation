WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        SUM(COALESCE(V.VoteTypeId = 2, 0)) AS TotalUpVotesReceived
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        TotalUpVotesReceived
    FROM 
        UserStats
    WHERE 
        Reputation > 1000
    ORDER BY 
        TotalUpVotesReceived DESC
    LIMIT 10
)
SELECT 
    T.UserId,
    T.DisplayName,
    T.Reputation,
    T.TotalPosts,
    T.TotalAnswers,
    T.TotalQuestions,
    T.TotalUpVotesReceived,
    COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
    COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
    COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
FROM 
    TopUsers T
LEFT JOIN 
    Badges B ON T.UserId = B.UserId
GROUP BY 
    T.UserId, T.DisplayName, T.Reputation, T.TotalPosts, T.TotalAnswers, T.TotalQuestions, T.TotalUpVotesReceived
ORDER BY 
    T.TotalUpVotesReceived DESC;
