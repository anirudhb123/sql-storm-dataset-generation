WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        COUNT(CASE WHEN P.ClosedDate IS NOT NULL THEN 1 END) AS ClosedPosts,
        COUNT(DISTINCT P.Tags) AS UniqueTags
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
CombinedStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        COALESCE(P.TotalPosts, 0) AS TotalPosts,
        COALESCE(P.Questions, 0) AS Questions,
        COALESCE(P.Answers, 0) AS Answers,
        COALESCE(P.ClosedPosts, 0) AS ClosedPosts,
        COALESCE(P.UniqueTags, 0) AS UniqueTags,
        U.UpVotes,
        U.DownVotes,
        U.GoldBadges,
        U.SilverBadges,
        U.BronzeBadges
    FROM 
        UserStats U
    LEFT JOIN 
        PostStats P ON U.UserId = P.OwnerUserId
),
RankedStats AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Reputation DESC, TotalPosts DESC) AS ReputationRank,
        DENSE_RANK() OVER (PARTITION BY CASE WHEN TotalPosts = 0 THEN 'NoPosts' ELSE 'HasPosts' END ORDER BY Reputation DESC) AS PostsRank
    FROM 
        CombinedStats
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    Questions,
    Answers,
    ClosedPosts,
    UniqueTags,
    UpVotes,
    DownVotes,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    ReputationRank,
    PostsRank,
    CASE 
        WHEN TotalPosts > 0 AND UpVotes > DownVotes THEN 'Active' 
        WHEN TotalPosts = 0 THEN 'Inactive' 
        ELSE 'Controversial' 
    END AS ActivityStatus
FROM 
    RankedStats
WHERE 
    (UpVotes > 50 OR DownVotes < 10)
    AND EXISTS (
        SELECT 1 
        FROM Tags T 
        JOIN Posts P ON T.ExcerptPostId = P.Id 
        WHERE T.Count > 100 AND P.OwnerUserId = RankedStats.UserId
    )
ORDER BY 
    ReputationRank, TotalPosts DESC
LIMIT 100;
