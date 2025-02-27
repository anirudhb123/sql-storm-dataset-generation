WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(U.Reputation) AS AvgReputation
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        SUM(COALESCE(V.VoteTypeId = 2, 0)) AS TotalUpVotes,
        SUM(COALESCE(V.VoteTypeId = 3, 0)) AS TotalDownVotes
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.CreationDate
),
RankedPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY PD.CreationDate ORDER BY PD.TotalUpVotes DESC) AS Rank
    FROM PostDetails PD
    WHERE PD.CommentCount > 5
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    R.Title,
    R.CreationDate,
    UPS.TotalVotes,
    UPS.UpVotes,
    UPS.DownVotes,
    R.CommentCount as PostCommentCount,
    R.Rank
FROM UserVoteStats UPS
JOIN RankedPosts R ON UPS.TotalVotes > 10
ORDER BY UPS.TotalVotes DESC, R.CommentCount DESC;
