WITH UserTagCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT T.Id) AS TagCount,
        SUM(CASE 
            WHEN B.Class = 1 THEN 1 
            ELSE 0 
        END) AS GoldBadges,
        SUM(CASE 
            WHEN B.Class = 2 THEN 1 
            ELSE 0 
        END) AS SilverBadges,
        SUM(CASE 
            WHEN B.Class = 3 THEN 1 
            ELSE 0 
        END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Tags T ON T.Id IN (SELECT UNNEST(string_to_array(P.Tags, '><'))) -- Split the Tags column
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TagCount,
        GoldBadges, 
        SilverBadges, 
        BronzeBadges,
        RANK() OVER (ORDER BY TagCount DESC, GoldBadges DESC, SilverBadges DESC, BronzeBadges DESC) AS UserRank
    FROM UserTagCounts
),
EnhancedUserHistory AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        P.Title,
        CASE 
            WHEN PH.PostHistoryTypeId = 10 THEN 'Post Closed' 
            WHEN PH.PostHistoryTypeId = 11 THEN 'Post Reopened' 
            ELSE 'Other Change' 
        END AS ChangeType,
        PH.Comment
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    JOIN Users U ON PH.UserId = U.Id
)
SELECT 
    TU.DisplayName,
    TU.TagCount,
    TU.GoldBadges,
    TU.SilverBadges,
    TU.BronzeBadges,
    E.PostId,
    E.Title,
    E.ChangeType,
    COUNT(DISTINCT E.PostId) AS TotalChanges
FROM TopUsers TU
LEFT JOIN EnhancedUserHistory E ON TU.UserId = E.UserId
WHERE TU.UserRank <= 10 -- Limiting to top 10 users
GROUP BY TU.DisplayName, TU.TagCount, TU.GoldBadges, TU.SilverBadges, TU.BronzeBadges, E.PostId, E.Title, E.ChangeType
ORDER BY TU.TagCount DESC, TU.GoldBadges DESC;
