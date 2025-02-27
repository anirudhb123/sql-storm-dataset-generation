WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 3 WHEN B.Class = 2 THEN 2 WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BadgeScore
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        AVG(P.Score) OVER (PARTITION BY P.OwnerUserId) AS AvgScore
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    GROUP BY P.Id
),
RankedPosts AS (
    SELECT 
        PS.*,
        RANK() OVER (ORDER BY PS.AvgScore DESC, PS.CommentCount DESC) AS PostRank
    FROM PostStatistics PS
)
SELECT 
    RP.PostId,
    RP.Title,
    U.DisplayName AS OwnerDisplayName,
    UR.UpVotes,
    UR.DownVotes,
    RP.CommentCount,
    RP.AnswerCount,
    RP.Score,
    RP.PostRank
FROM RankedPosts RP
JOIN UserReputation UR ON RP.OwnerUserId = UR.UserId
WHERE RP.CreatedDate >= NOW() - INTERVAL '1 year' -- Recent posts
  AND (RP.AnswerCount > 0 OR RP.CommentCount > 10) -- Popular posts
ORDER BY RP.PostRank
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
