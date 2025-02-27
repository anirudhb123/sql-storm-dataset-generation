WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
UserRankings AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        COUNT(DISTINCT P.OwnerUserId) AS UsersInvolved
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        PostCount > 10
),
TopUsers AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        COALESCE(UT.PostCount, 0) AS UserPostCount,
        COALESCE(UT.CommentCount, 0) AS UserCommentCount,
        COALESCE(TT.TagCount, 0) AS UserTagCount
    FROM 
        Users U
    LEFT JOIN 
        UserStats UT ON U.Id = UT.UserId
    LEFT JOIN 
        (SELECT 
            COUNT(DISTINCT T.Id) AS TagCount,
            U.Id AS UserId
         FROM 
            Users U
         JOIN 
            Posts P ON U.Id = P.OwnerUserId
         JOIN 
            Tags T ON P.Tags LIKE '%' || T.TagName || '%'
         GROUP BY 
            U.Id) TT ON U.Id = TT.UserId
    WHERE 
        U.Reputation > 1000
)
SELECT 
    R.DisplayName AS UserName,
    R.ReputationRank,
    R.PostCount,
    R.CommentCount,
    R.GoldBadges,
    R.SilverBadges,
    R.BronzeBadges,
    T.TagName,
    T.PostCount AS TagPostCount,
    T.UsersInvolved AS TagUsersInvolved,
    CASE 
        WHEN R.ReputationRank < 6 THEN 'Top Contributor'
        WHEN R.ReputationRank BETWEEN 6 AND 20 THEN 'Established User'
        ELSE 'New User'
    END AS UserStatus
FROM 
    UserRankings R
LEFT JOIN 
    PopularTags T ON T.UsersInvolved >= R.PostCount OR T.PostCount <= R.CommentCount
WHERE 
    R.ReputationRank <= 50
ORDER BY 
    R.Reputation DESC, 
    T.TagPostCount DESC;
