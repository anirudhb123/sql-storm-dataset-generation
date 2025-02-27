WITH RECURSIVE UserReputation AS (
    SELECT Id, Reputation, CreationDate, DisplayName,
        CASE
            WHEN Reputation >= 1000 THEN 'High'
            WHEN Reputation >= 100 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM Users
), 
RecentPosts AS (
    SELECT Id, Title, CreationDate, Score, ViewCount, OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY OwnerUserId ORDER BY CreationDate DESC) AS RecentRank
    FROM Posts
    WHERE CreationDate > NOW() - INTERVAL '1 year'
),
PostTags AS (
    SELECT P.Id AS PostId, 
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM Posts P
    JOIN UNNEST(STRING_TO_ARRAY(P.Tags, '><')) AS TagName ON TRUE
    JOIN Tags T ON T.TagName = TagName
    GROUP BY P.Id
),
UserBadges AS (
    SELECT UserId, 
        COUNT(*) FILTER (WHERE Class = 1) AS GoldBadges, 
        COUNT(*) FILTER (WHERE Class = 2) AS SilverBadges, 
        COUNT(*) FILTER (WHERE Class = 3) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
)
SELECT U.Id AS UserId, 
       U.DisplayName, 
       U.Reputation, 
       U.ReputationCategory, 
       RP.Title AS RecentPostTitle, 
       RP.CreationDate AS RecentPostDate, 
       RP.Score AS PostScore, 
       PT.Tags AS PostTags,
       COALESCE(UB.GoldBadges, 0) AS GoldBadges,
       COALESCE(UB.SilverBadges, 0) AS SilverBadges,
       COALESCE(UB.BronzeBadges, 0) AS BronzeBadges
FROM UserReputation U
LEFT JOIN RecentPosts RP ON U.Id = RP.OwnerUserId AND RP.RecentRank = 1
LEFT JOIN PostTags PT ON RP.Id = PT.PostId
LEFT JOIN UserBadges UB ON U.Id = UB.UserId
WHERE U.Reputation > 100 
ORDER BY U.Reputation DESC, RP.CreationDate DESC;

-- This query benchmark focuses on the users with a reputation of more than 100.
-- It fetches the latest post of each user along with their reputation category, 
-- the tags associated with that post, and their badge counts while employing 
-- recursive CTEs, window functions, and outer joins for performance comparisons.
