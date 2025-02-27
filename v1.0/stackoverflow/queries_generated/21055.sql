WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.PostTypeId,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
RecentBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId AND B.Date >= NOW() - INTERVAL '6 months'
    GROUP BY 
        U.Id
),
PostHistoryDetails AS (
    SELECT
        PH.PostId,
        PH.UserId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        CASE 
            WHEN PH.PostHistoryTypeId = 10 THEN (SELECT Name FROM CloseReasonTypes WHERE Id = PH.Comment::int)
            ELSE NULL
        END AS CloseReason
    FROM 
        PostHistory PH
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL '1 month'
),
PopularTags AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM 
        UNNEST(string_to_array(Tags, ',')) AS TagName
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 10
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    UB.DispName AS PostOwner,
    RB.BadgeCount,
    RB.BadgeNames,
    PT.TagName,
    PH.CloseReason
FROM 
    RankedPosts RP
JOIN 
    RecentBadges RB ON RP.OwnerUserId = RB.UserId
LEFT JOIN 
    PopularTags PT ON RP.PostId IN (SELECT PostId FROM Posts WHERE Tags LIKE '%' || PT.TagName || '%')
LEFT JOIN 
    Users UB ON RP.OwnerUserId = UB.Id
LEFT JOIN 
    PostHistoryDetails PH ON RP.PostId = PH.PostId
WHERE 
    RP.PostRank = 1
AND 
    (RB.BadgeCount > 0 OR PH.CloseReason IS NOT NULL)
ORDER BY 
    RP.CreationDate DESC
LIMIT 100;
