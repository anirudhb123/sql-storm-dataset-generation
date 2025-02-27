WITH RECURSIVE UserPostCount AS (
    SELECT
        U.Id AS UserId,
        COUNT(P.Id) AS PostCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
),
RecentPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    WHERE P.CreationDate > CURRENT_DATE - INTERVAL '30 days'
),
ClosedPostHistory AS (
    SELECT
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        PH.UserId,
        PH.PostHistoryTypeId,
        RANK() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS ClosureRank
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11) -- Only closed or reopened posts
)
SELECT
    U.DisplayName AS User,
    U.Reputation,
    Coalesce(UPC.PostCount, 0) AS TotalPosts,
    COUNT(DISTINCT RP.PostId) AS RecentPostsCount,
    COUNT(DISTINCT CPH.PostId) AS ClosedPostCount,
    NVL(MAX(CPH.CreationDate), 'Never') AS LastClosedDate,
    SUM(CASE WHEN PO.Id IS NOT NULL THEN 1 ELSE 0 END) AS LikeCount, -- Assuming VoteTypeId 2 is for Upvotes
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags,
    U.Location,
    COALESCE(SUM(CASE WHEN BD.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
    COALESCE(SUM(CASE WHEN BD.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
    COALESCE(SUM(CASE WHEN BD.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
FROM Users U
LEFT JOIN UserPostCount UPC ON U.Id = UPC.UserId
LEFT JOIN RecentPosts RP ON U.Id = RP.OwnerUserId
LEFT JOIN ClosedPostHistory CPH ON CPH.UserId = U.Id AND CPH.ClosureRank = 1
LEFT JOIN Posts PO ON PO.OwnerUserId = U.Id
LEFT JOIN Votes V ON V.PostId = PO.Id AND V.VoteTypeId = 2 -- Counting Upvotes
LEFT JOIN Badges BD ON BD.UserId = U.Id
LEFT JOIN STRING_TO_ARRAY(P.Tags, ',') AS T ON T.TagName IN (SELECT DISTINCT Tags FROM Posts WHERE OwnerUserId = U.Id) 
GROUP BY U.Id, U.DisplayName, U.Reputation, U.Location
ORDER BY TotalPosts DESC, Reputation DESC
LIMIT 50;

