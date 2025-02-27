WITH RecursiveUserVotes AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        V.VoteTypeId,
        COUNT(V.Id) AS VoteCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, V.VoteTypeId
),
TopUserVotes AS (
    SELECT
        UserId,
        DisplayName,
        SUM(CASE WHEN VoteTypeId = 2 THEN VoteCount ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN VoteCount ELSE 0 END) AS TotalDownVotes,
        RANK() OVER (ORDER BY SUM(CASE WHEN VoteTypeId = 2 THEN VoteCount ELSE 0 END) DESC) AS UpVoteRank
    FROM RecursiveUserVotes
    GROUP BY UserId, DisplayName
    HAVING SUM(CASE WHEN VoteTypeId IN (2, 3) THEN VoteCount ELSE 0 END) > 10
),
PostActivity AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(COUNT(C.Id), 0) AS CommentCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVoteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount
),
ClosedPosts AS (
    SELECT
        PH.PostId,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.PostId
),
FinalPostStats AS (
    SELECT
        PA.PostId,
        PA.Title,
        PA.CreationDate,
        PA.ViewCount,
        PA.CommentCount,
        PA.UpVoteCount,
        PA.DownVoteCount,
        COALESCE(CLP.LastClosedDate, 'Never Closed') AS LastClosedDate
    FROM PostActivity PA
    LEFT JOIN ClosedPosts CLP ON PA.PostId = CLP.PostId
)
SELECT
    FPS.PostId,
    FPS.Title,
    FPS.CreationDate,
    FPS.ViewCount,
    FPS.CommentCount,
    FPS.UpVoteCount,
    FPS.DownVoteCount,
    FPS.LastClosedDate,
    TUV.DisplayName,
    TUV.TotalUpVotes,
    TUV.TotalDownVotes
FROM FinalPostStats FPS
LEFT JOIN TopUserVotes TUV ON FPS.UpVoteCount > 0 OR FPS.DownVoteCount > 0
WHERE FPS.UpVoteCount > FPS.DownVoteCount
ORDER BY FPS.UpVoteCount DESC, FPS.ViewCount DESC;
