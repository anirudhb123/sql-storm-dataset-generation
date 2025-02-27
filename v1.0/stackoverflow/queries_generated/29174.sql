-- This query benchmarks string processing capabilities by extracting and analyzing tags from posts,
-- while also retrieving related user information and their badge counts.

WITH TagCounts AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        P.Id AS PostId
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Only consider questions
),
UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
TagStats AS (
    SELECT 
        TC.TagName,
        COUNT(TC.PostId) AS PostCount,
        COUNT(DISTINCT U.UserId) AS UserCount,
        SUM(CASE WHEN UBADGE.BadgeCount IS NOT NULL THEN UBADGE.BadgeCount ELSE 0 END) AS TotalBadges
    FROM 
        TagCounts TC
    LEFT JOIN 
        Posts P ON TC.PostId = P.Id
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        UserBadgeCounts UBADGE ON U.Id = UBADGE.UserId
    GROUP BY 
        TC.TagName
)

SELECT 
    T.TagName,
    T.PostCount,
    T.UserCount,
    T.TotalBadges,
    -- Generate a summary for each tag with string aggregations
    STRING_AGG(DISTINCT U.DisplayName, ', ') AS UsersWhoAsked,
    STRING_AGG(DISTINCT B.Name, ', ') AS BadgesHeld
FROM 
    TagStats T
LEFT JOIN 
    Users U ON U.Id IN (SELECT OwnerUserId FROM Posts WHERE Tags LIKE '%' || T.TagName || '%')
LEFT JOIN 
    Badges B ON B.UserId = U.Id
GROUP BY 
    T.TagName, T.PostCount, T.UserCount, T.TotalBadges
ORDER BY 
    T.PostCount DESC;
