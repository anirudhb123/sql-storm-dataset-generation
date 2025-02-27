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
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecencyRank,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVoteCount,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.OwnerUserId, P.CreationDate, P.Score
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.LastAccessDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        MAX(P.CreationDate) AS LastPostDate,
        MAX(P.Score) AS HighestScore,
        AVG(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS AverageScore,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS HighViewsCount
    FROM 
        Users U
    LEFT JOIN 
        ActivePosts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.LastAccessDate
),
Ranking AS (
    SELECT 
        UA.*,
        RANK() OVER (ORDER BY UA.Reputation DESC, UA.LastAccessDate DESC) AS UserRank
    FROM 
        UserActivity UA
)
SELECT 
    RB.UserId,
    RB.DisplayName,
    RB.Reputation,
    RB.LastAccessDate,
    RB.TotalPosts,
    RB.LastPostDate,
    RB.HighestScore,
    RB.AverageScore,
    RB.HighViewsCount,
    UB.TotalBadges,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    RB.UserRank,
    CASE 
        WHEN RB.TotalPosts = 0 THEN 'No Activity'
        WHEN RB.Reputation >= 1000 THEN 'Active Contributor'
        ELSE 'New User'
    END AS UserStatus
FROM 
    Ranking RB
JOIN 
    UserBadges UB ON RB.UserId = UB.UserId
WHERE 
    RB.HighViewsCount > 5
ORDER BY 
    RB.UserRank, RB.LastAccessDate DESC;
