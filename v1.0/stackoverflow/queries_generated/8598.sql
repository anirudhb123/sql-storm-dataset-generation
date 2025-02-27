WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        SUM(V.UserId IS NOT NULL) AS VoteCount, 
        COUNT(C.Id) AS CommentCount, 
        COUNT(DISTINCT P.Id) AS PostCount, 
        SUM(B.Class = 1) AS GoldBadges, 
        SUM(B.Class = 2) AS SilverBadges, 
        SUM(B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),

TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        VoteCount, 
        CommentCount, 
        PostCount, 
        GoldBadges, 
        SilverBadges, 
        BronzeBadges,
        RANK() OVER (ORDER BY VoteCount DESC) AS VoteRank,
        RANK() OVER (ORDER BY CommentCount DESC) AS CommentRank,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank
    FROM 
        UserEngagement
)

SELECT 
    T.DisplayName,
    T.VoteCount,
    T.CommentCount,
    T.PostCount,
    T.GoldBadges,
    T.SilverBadges,
    T.BronzeBadges,
    CASE 
        WHEN T.VoteRank = 1 THEN 'Top Voter'
        ELSE NULL
    END AS VoteTitle,
    CASE 
        WHEN T.CommentRank = 1 THEN 'Top Commenter'
        ELSE NULL
    END AS CommentTitle,
    CASE 
        WHEN T.PostRank = 1 THEN 'Top Poster'
        ELSE NULL
    END AS PostTitle
FROM 
    TopUsers T
WHERE 
    T.VoteCount > 100 OR T.CommentCount > 50 OR T.PostCount > 20
ORDER BY 
    T.VoteCount DESC, T.CommentCount DESC, T.PostCount DESC;
