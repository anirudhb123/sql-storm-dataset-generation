
WITH UserBadges AS (
    SELECT 
        Users.Id AS UserId,
        COUNT(CASE WHEN Badges.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Badges.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Badges.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users
    LEFT JOIN 
        Badges ON Users.Id = Badges.UserId 
    GROUP BY 
        Users.Id
),
RecentPosts AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.OwnerUserId,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        @row_number := IF(@current_user = Posts.OwnerUserId, @row_number + 1, 1) AS PostRank,
        COUNT(CASE WHEN Votes.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN Votes.VoteTypeId = 3 THEN 1 END) AS DownVotesCount,
        @current_user := Posts.OwnerUserId
    FROM 
        Posts
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    CROSS JOIN (SELECT @row_number := 0, @current_user := NULL) AS r
    WHERE 
        Posts.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        Posts.Id
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.UpVotesCount,
    RP.DownVotesCount,
    CASE 
        WHEN RP.Score IS NULL THEN 'Unknown'
        WHEN RP.Score > 10 THEN 'Highly Scored'
        WHEN RP.Score BETWEEN 1 AND 10 THEN 'Moderately Scored'
        ELSE 'Low Scored'
    END AS ScoreCategory
FROM 
    Users U
LEFT JOIN 
    UserBadges UB ON U.Id = UB.UserId
LEFT JOIN 
    RecentPosts RP ON U.Id = RP.OwnerUserId
WHERE 
    RP.PostRank = 1 
    AND (U.Reputation > 100 OR (RP.Score IS NOT NULL AND RP.Score > 0))
ORDER BY 
    U.Reputation DESC, RP.CreationDate DESC
LIMIT 50;
