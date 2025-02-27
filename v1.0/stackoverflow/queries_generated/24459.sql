WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostsCreated,
        COALESCE(SUM(B.Class), 0) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.LastActivityDate,
        P.Score,
        P.ViewCount,
        P.ANSWERCOUNT,
        COALESCE(PH.Comment, 'None') AS LastEditComment,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.LastActivityDate DESC) AS rn
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5) -- Edit Title, Edit Body
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UVs.UpVotes,
    UVs.DownVotes,
    UVs.PostsCreated,
    UVs.BadgeCount,
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.LastActivityDate,
    PD.Score,
    PD.ViewCount,
    PD.ANSWERCOUNT,
    PD.LastEditComment
FROM UserVoteSummary UVs
JOIN Posts P ON UVs.UserId = P.OwnerUserId
JOIN PostDetails PD ON PD.PostId = P.Id
WHERE UVs.PostsCreated > 0
  AND PVs.UpVotes > PD.Score / NULLIF(PD.ViewCount, 0) -- Look for cases where upvotes exceed a specific ratio
ORDER BY UVs.UpVotes DESC, PD.LastActivityDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

-- Additional filtering based on null and special logic
UNION ALL
SELECT 
    U.DisplayName,
    U.Reputation,
    0 AS UpVotes,
    0 AS DownVotes,
    0 AS PostsCreated,
    0 AS BadgeCount,
    NULL AS PostId,
    NULL AS Title,
    NULL AS CreationDate,
    NULL AS LastActivityDate,
    NULL AS Score,
    NULL AS ViewCount,
    NULL AS ANSWERCOUNT,
    'No posts available' AS LastEditComment
FROM Users U
WHERE NOT EXISTS (SELECT 1 FROM Posts P WHERE P.OwnerUserId = U.Id)
AND U.Reputation < 50
ORDER BY 1;
