
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        @rn := IF(@prev_owner = P.OwnerUserId, @rn + 1, 1) AS rn,
        @prev_owner := P.OwnerUserId
    FROM 
        Posts P,
        (SELECT @rn := 0, @prev_owner := NULL) init
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 30 DAY
    ORDER BY 
        P.OwnerUserId, P.CreationDate DESC
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS TagCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    UA.DisplayName,
    UA.Reputation,
    UA.PostCount,
    UA.CommentCount,
    UA.TotalBounty,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate,
    PT.TagName AS PopularTag
FROM 
    UserActivity UA
LEFT JOIN 
    RecentPosts RP ON UA.UserId = RP.OwnerUserId AND RP.rn = 1
CROSS JOIN 
    PopularTags PT
WHERE 
    UA.TotalBounty IS NOT NULL
ORDER BY 
    UA.Reputation DESC, 
    RP.CreationDate DESC;
