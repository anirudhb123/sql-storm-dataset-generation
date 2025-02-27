WITH UserVotes AS (
    SELECT
        U.Id AS UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Users U
    LEFT JOIN
        Votes V ON U.Id = V.UserId
    GROUP BY
        U.Id
),
PostAnalytics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.CreationDate END), '1900-01-01') AS ClosedDate,
        P.CreationDate AS PostCreationDate,
        DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    LEFT JOIN
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY
        P.Id
)
SELECT
    PA.PostId,
    PA.Title,
    PA.Score,
    PA.ViewCount,
    PA.AnswerCount,
    PA.CommentCount,
    PA.ClosedDate,
    UA.UserId,
    UA.VoteCount,
    UA.UpVotes,
    UA.DownVotes
FROM
    PostAnalytics PA
LEFT JOIN
    UserVotes UA ON PA.PostId IN (
        SELECT PostId
        FROM Votes
        WHERE UserId = UA.UserId
    )
WHERE
    PA.ViewCount > 50
    AND (PA.ClosedDate IS NULL OR PA.ClosedDate < CURRENT_TIMESTAMP - INTERVAL '30 days')
ORDER BY
    PA.Score DESC,
    PA.ViewCount DESC
LIMIT 100
OFFSET 0;
