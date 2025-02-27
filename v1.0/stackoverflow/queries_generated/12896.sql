-- Performance Benchmarking Query
WITH UserVoteStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId IN (10, 11) THEN 1 ELSE 0 END) AS VoteChanges
    FROM
        Users U
    LEFT JOIN
        Votes V ON U.Id = V.UserId
    GROUP BY
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.AnswerCount,
        COUNT(C.Id) AS CommentCount
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    GROUP BY
        P.Id, P.Title, P.ViewCount, P.AnswerCount
)
SELECT
    U.UserId,
    U.DisplayName,
    U.TotalVotes,
    U.UpVotes,
    U.VoteChanges,
    P.PostId,
    P.Title AS PostTitle,
    P.ViewCount,
    P.AnswerCount,
    P.CommentCount
FROM
    UserVoteStats U
CROSS JOIN
    PostStats P
ORDER BY
    U.TotalVotes DESC,
    P.ViewCount DESC
LIMIT 100;
