WITH UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(UP.VoteCount, 0) AS UpVoteCount,
        COALESCE(DOWN.VoteCount, 0) AS DownVoteCount,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount FROM Votes WHERE VoteTypeId = 2 GROUP BY PostId
    ) UP ON P.Id = UP.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount FROM Votes WHERE VoteTypeId = 3 GROUP BY PostId
    ) DOWN ON P.Id = DOWN.PostId
),
AggregatedUserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(B.TotalBadges, 0) AS TotalBadges,
        COALESCE(PD.TotalPosts, 0) AS TotalPosts,
        SUM(CASE WHEN BD.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN BD.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN BD.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN UserBadges B ON U.Id = B.UserId
    LEFT JOIN (
        SELECT OwnerUserId, COUNT(*) AS TotalPosts
        FROM Posts
        GROUP BY OwnerUserId
    ) PD ON U.Id = PD.OwnerUserId
    LEFT JOIN Badges BD ON U.Id = BD.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, PD.TotalPosts
),
FinalOutput AS (
    SELECT 
        A.UserId,
        A.DisplayName,
        A.Reputation,
        A.TotalBadges,
        A.TotalPosts,
        A.GoldBadges,
        A.SilverBadges,
        A.BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY A.Reputation DESC) AS UserRank,
        (SELECT COUNT(*) FROM Posts P WHERE P.OwnerUserId = A.UserId) AS UserPostCount
    FROM 
        AggregatedUserStats A
)
SELECT 
    F.UserId,
    F.DisplayName,
    F.Reputation,
    F.TotalBadges,
    F.TotalPosts,
    F.GoldBadges,
    F.SilverBadges,
    F.BronzeBadges,
    F.UserRank,
    F.UserPostCount
FROM 
    FinalOutput F
WHERE 
    F.TotalBadges IS NOT NULL 
    AND (F.TotalPosts > 10 OR F.Reputation > 500)
ORDER BY 
    F.Reputation DESC;
