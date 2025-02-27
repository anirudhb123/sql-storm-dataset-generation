
WITH UserMeta AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 30 DAY
),
UserActivity AS (
    SELECT 
        UM.UserId,
        UM.DisplayName,
        SUM(COALESCE(RP.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(RP.Score, 0)) AS TotalScore,
        COUNT(DISTINCT RP.PostId) AS PostsCreated,
        COUNT(DISTINCT C.Id) AS CommentsMade
    FROM 
        UserMeta UM
    LEFT JOIN 
        RecentPosts RP ON UM.UserId = RP.OwnerUserId
    LEFT JOIN 
        Comments C ON C.UserId = UM.UserId
    GROUP BY 
        UM.UserId, UM.DisplayName
)
SELECT 
    UA.DisplayName,
    UA.TotalViews,
    UA.TotalScore,
    UA.PostsCreated,
    UA.CommentsMade,
    U.Reputation,
    U.CreationDate,
    CASE 
        WHEN U.Reputation > 1000 THEN 'High Reputation'
        WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    (SELECT 
        GROUP_CONCAT(DISTINCT T.TagName SEPARATOR ', ') 
     FROM 
        Posts P
     JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', numbers.n), ',', -1) AS TagName
         FROM 
            (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) AS numbers 
         WHERE 
            CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, ',', '')) >= numbers.n - 1) AS Tag 
     JOIN 
        Tags T ON T.TagName = Tag.TagName 
     WHERE 
        P.OwnerUserId = UA.UserId
    ) AS TagsUsed
FROM 
    UserActivity UA
JOIN 
    Users U ON UA.UserId = U.Id
WHERE 
    UA.PostsCreated > 0
ORDER BY 
    UA.TotalScore DESC, UA.TotalViews DESC
LIMIT 10;
