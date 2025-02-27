WITH TopBadges AS (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    WHERE 
        Class = 1 -- Gold badges only
    GROUP BY 
        UserId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        T.BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        TopBadges T ON U.Id = T.UserId
    WHERE 
        U.Reputation > 1000 -- Only users with reputation greater than 1000
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(P.Tags, '>')) AS Tag
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
TagUsage AS (
    SELECT 
        Tag, 
        COUNT(*) AS UsageCount
    FROM 
        PopularTags
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 10
),
PostsWithUserInfo AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.Score, 
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '6 months'
)
SELECT 
    P.PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    TU.DisplayName AS TopUserDisplayName,
    TU.Reputation AS TopUserReputation,
    TU.BadgeCount,
    TU.UserId,
    (SELECT STRING_AGG(TU.DisplayName, ', ') 
     FROM TopUsers TU2 WHERE TU2.Reputation > TU.Reputation 
     AND TU2.BadgeCount >= TU.BadgeCount) AS Competitors
FROM 
    PostsWithUserInfo P
JOIN 
    TopUsers TU ON P.OwnerUserId = TU.UserId
JOIN 
    TagUsage TUg ON TUg.Tag = ANY(string_to_array(P.Tags, '>')) 
ORDER BY 
    P.Score DESC, 
    P.CreationDate DESC
LIMIT 20;
