WITH RecursiveTagCount AS (
    SELECT
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM
        Tags T
    LEFT JOIN Posts P ON T.Id = ANY(string_to_array(P.Tags, '::int'))::int[]
    GROUP BY
        T.Id, T.TagName
    HAVING
        COUNT(P.Id) > 0
),

RecentActivePosts AS (
    SELECT
        P.Id,
        P.Title,
        P.OwnerUserId,
        P.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.LastActivityDate DESC) AS rn
    FROM
        Posts P
    WHERE
        P.LastActivityDate >= NOW() - INTERVAL '30 days'
),

UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM
        Users U
),

PostHistoryDetails AS (
    SELECT
        PH.Id AS PostHistoryId,
        P.Title,
        PH.UserId,
        U.Reputation AS UserReputation,
        PH.CreationDate,
        PH.Comment,
        PH.PostHistoryTypeId
    FROM
        PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    JOIN Users U ON PH.UserId = U.Id
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL '1 year'
)

SELECT
    U.Id AS UserId,
    U.DisplayName,
    COALESCE(PH.UserReputation, 0) AS UserReputation,
    COUNT(DISTINCT PH.PostHistoryId) AS TotalEdits,
    SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS TotalCloseOpenActions,
    AVG(COALESCE(RTC.PostCount, 0)) AS AvgPostsPerTag,
    COUNT(DISTINCT RAN.PostId) AS RecentPostsCount,
    STRING_AGG(DISTINCT RTC.TagName, ', ') AS ActiveTags
FROM
    Users U
LEFT JOIN UserReputation PH ON U.Id = PH.UserId
LEFT JOIN PostHistoryDetails PH ON U.Id = PH.UserId
LEFT JOIN RecursiveTagCount RTC ON RTC.TagId IN (SELECT UNNEST(string_to_array(PH.Tags, '::int'))::int[])
LEFT JOIN RecentActivePosts RAN ON U.Id = RAN.OwnerUserId
WHERE
    (PH.UserReputation > 1000 OR PH.UserReputation IS NULL)
GROUP BY
    U.Id, U.DisplayName
ORDER BY
    UserReputation DESC, TotalEdits DESC;
