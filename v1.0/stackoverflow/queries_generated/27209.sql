WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId IN (6, 10, 11) THEN 1 ELSE 0 END) AS PostVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        UpVotes,
        DownVotes,
        PostVotes,
        RANK() OVER (ORDER BY TotalPosts DESC) AS RankByPosts,
        RANK() OVER (ORDER BY UpVotes DESC) AS RankByUpVotes
    FROM 
        UserActivity
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalComments,
    TU.UpVotes,
    TU.DownVotes,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    TU.RankByPosts,
    TU.RankByUpVotes
FROM 
    TopUsers TU
LEFT JOIN 
    UserBadges UB ON TU.UserId = UB.UserId
WHERE 
    TU.RankByPosts <= 10 OR TU.RankByUpVotes <= 10
ORDER BY 
    TU.RankByPosts, TU.RankByUpVotes;
