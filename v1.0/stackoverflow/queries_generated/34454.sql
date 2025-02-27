WITH RecursiveTagCounts AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount
    FROM Tags
    LEFT JOIN Posts ON Tags.Id = Posts.Id
    GROUP BY Tags.TagName
), TagStats AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM RecursiveTagCounts
),
UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostsVotedOn
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON V.PostId = P.Id
    GROUP BY U.Id
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COALESCE(COUNT(C.Comments), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END), 0) AS CloseOpenCount,
        DENSE_RANK() OVER (ORDER BY P.ViewCount DESC) AS ViewRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE P.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY P.Id, P.Title, P.ViewCount
)
SELECT 
    T.TagName,
    T.PostCount,
    U.UserId,
    U.DisplayName,
    U.UpVotes,
    U.DownVotes,
    PA.PostId,
    PA.Title,
    PA.ViewCount,
    PA.CommentCount,
    PA.CloseOpenCount,
    PA.ViewRank
FROM TagStats T
LEFT JOIN UserVoteStats U ON U.PostsVotedOn > 0
LEFT JOIN PostActivity PA ON PA.ViewCount > 100
WHERE U.UpVotes > 50 OR U.DownVotes < 10
ORDER BY T.Rank, U.UpVotes DESC, PA.ViewRank;
