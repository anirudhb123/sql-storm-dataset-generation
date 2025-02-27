
WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT V.PostId) AS TotalVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COALESCE(UPV.UpVotes, 0) AS UpVotes,
        COALESCE(DNV.DownVotes, 0) AS DownVotes,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        FIND_IN_SET(P.CreationDate, (
            SELECT GROUP_CONCAT(CreationDate ORDER BY P.CreationDate DESC) FROM Posts WHERE OwnerUserId = P.OwnerUserId
        )) AS PostRank
    FROM Posts P
    LEFT JOIN UserVotes UPV ON P.OwnerUserId = UPV.UserId
    LEFT JOIN UserVotes DNV ON P.OwnerUserId = DNV.UserId
    WHERE P.CreationDate >= NOW() - INTERVAL 1 YEAR
),
RankedPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.OwnerUserId,
        PD.UpVotes,
        PD.DownVotes,
        PD.ViewCount,
        PD.AnswerCount,
        PD.CommentCount,
        PD.PostRank,
        @rank := @rank + 1 AS OverallRank
    FROM PostDetails PD, (SELECT @rank := 0) r
    ORDER BY PD.UpVotes DESC, PD.ViewCount DESC
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    RP.UpVotes,
    RP.DownVotes,
    RP.ViewCount,
    RP.AnswerCount,
    RP.CommentCount,
    RP.OverallRank
FROM RankedPosts RP
JOIN Users U ON RP.OwnerUserId = U.Id
WHERE RP.OverallRank <= 10
ORDER BY RP.OverallRank;
