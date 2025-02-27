WITH RecursiveTagCounts AS (
    SELECT
        T.Id AS TagId,
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM
        Tags T
    LEFT JOIN
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY
        T.Id
),
UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        SUM(U.Reputation) AS TotalReputation
    FROM
        Users U
    JOIN
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY
        U.Id
),
RecentPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM
        Posts P
    WHERE
        P.CreationDate >= NOW() - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT
        P.Id AS ClosedPostId,
        PH.PostId,
        PH.CreationDate AS ClosedDate,
        PH.Comment
    FROM
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE
        PH.PostHistoryTypeId = 10 -- Closed posts
)
SELECT
    U.DisplayName AS User,
    COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
    COUNT(DISTINCT RP.PostId) AS RecentPostCount,
    RT.TagName,
    RT.PostCount,
    CP.ClosedPostId,
    CP.ClosedDate
FROM
    Users U
LEFT JOIN
    Votes V ON V.UserId = U.Id
LEFT JOIN
    RecentPosts RP ON RP.PostId = V.PostId
LEFT JOIN
    RecursiveTagCounts RT ON RT.TagId IN (SELECT UNNEST(string_to_array(P.Tags, ','))::int) 
    LEFT JOIN
    ClosedPosts CP ON CP.PostId = RP.PostId
WHERE
    U.Reputation > 1000 -- Users with high reputation
GROUP BY
    U.Id, RT.TagName, RT.PostCount, CP.ClosedPostId, CP.ClosedDate
ORDER BY
    U.DisplayName, RT.TagName;

