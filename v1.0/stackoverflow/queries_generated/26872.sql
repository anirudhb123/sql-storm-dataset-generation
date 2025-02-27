WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        P.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 -- Only questions
        AND P.Score > 0
),
PostTagCounts AS (
    SELECT 
        P.Id,
        COUNT(TAG.TagName) AS TagCount
    FROM 
        Posts P
    CROSS JOIN 
        LATERAL unnest(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')) AS TAG(TagName)
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS UpvotedPosts,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    R.PostId,
    R.Title,
    R.Body,
    R.CreationDate,
    R.ViewCount,
    R.Score,
    R.OwnerDisplayName,
    TC.TagCount,
    UA.TotalPosts,
    UA.PopularPosts,
    UA.UpvotedPosts,
    UA.GoldBadges,
    UA.SilverBadges,
    UA.BronzeBadges,
    (SELECT STRING_AGG(DISTINCT T.TagName, ', ') 
     FROM UNNEST(string_to_array(substring(R.Tags, 2, length(R.Tags)-2), '><')) AS T(TagName)
     WHERE T.TagName IS NOT NULL) AS PostTags
FROM 
    RankedPosts R
JOIN 
    PostTagCounts TC ON R.PostId = TC.Id
JOIN 
    UserActivity UA ON R.OwnerUserId = UA.UserId
WHERE 
    R.PostRank <= 3
ORDER BY 
    R.ViewCount DESC, UA.TotalPosts DESC;
