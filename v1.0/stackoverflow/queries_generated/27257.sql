WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(COALESCE(V.VoteTypeId = 2,0)) AS TotalUpVotes,
        SUM(COALESCE(V.VoteTypeId = 3,0)) AS TotalDownVotes,
        SUM(COALESCE(B.Class = 1,0)) AS TotalGoldBadges,
        SUM(COALESCE(B.Class = 2,0)) AS TotalSilverBadges,
        SUM(COALESCE(B.Class = 3,0)) AS TotalBronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
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
        TotalGoldBadges,
        TotalSilverBadges,
        TotalBronzeBadges,
        RANK() OVER (ORDER BY TotalUpVotes DESC) AS UpvoteRank,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalComments DESC) AS CommentRank
    FROM 
        UserActivity
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    TotalGoldBadges,
    TotalSilverBadges,
    TotalBronzeBadges,
    UpvoteRank,
    PostRank,
    CommentRank
FROM 
    TopUsers
WHERE 
    UpvoteRank <= 10 OR PostRank <= 10 OR CommentRank <= 10
ORDER BY 
    GREATEST(UpvoteRank, PostRank, CommentRank);
