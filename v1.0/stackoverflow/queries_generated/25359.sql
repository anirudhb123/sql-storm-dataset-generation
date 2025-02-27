WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS ClosedPosts,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS ReopenedPosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id
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
),
UserTags AS (
    SELECT 
        U.Id AS UserId,
        STRING_AGG(DISTINCT T.TagName, ', ') AS FavoriteTags
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    JOIN 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2), '><')) AS T(TagName)
    GROUP BY 
        U.Id
)
SELECT 
    R.UserId,
    R.DisplayName,
    R.Reputation,
    R.PostCount,
    R.UpVotes,
    R.DownVotes,
    R.ClosedPosts,
    R.ReopenedPosts,
    COALESCE(B.GoldBadges, 0) AS GoldBadges,
    COALESCE(B.SilverBadges, 0) AS SilverBadges,
    COALESCE(B.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(T.FavoriteTags, 'None') AS FavoriteTags
FROM 
    UserReputation R
LEFT JOIN 
    UserBadges B ON R.UserId = B.UserId
LEFT JOIN 
    UserTags T ON R.UserId = T.UserId
ORDER BY 
    R.Reputation DESC, R.PostCount DESC;
