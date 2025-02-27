WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(B.Class = 1) AS GoldBadges,
        SUM(B.Class = 2) AS SilverBadges,
        SUM(B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY TotalUpVotes DESC, TotalPosts DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    Rank,
    DisplayName,
    TotalPosts,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    TopUsers
WHERE 
    Rank <= 10;
