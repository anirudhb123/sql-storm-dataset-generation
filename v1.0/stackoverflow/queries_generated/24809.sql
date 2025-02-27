WITH UserVoteStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT Votes.PostId) AS TotalVotes,
        COUNT(DISTINCT CASE WHEN Posts.PostTypeId = 1 THEN Posts.Id END) AS QuestionVotes,
        COUNT(DISTINCT CASE WHEN Posts.PostTypeId = 2 THEN Posts.Id END) AS AnswerVotes
    FROM Users
    LEFT JOIN Votes ON Votes.UserId = Users.Id
    LEFT JOIN Posts ON Posts.Id = Votes.PostId
    GROUP BY Users.Id, Users.DisplayName
), PostStats AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.OwnerUserId,
        COUNT(Comments.Id) AS CommentCount,
        COALESCE(SUM(Votes.VoteTypeId = 2)::int, 0) AS UpVoteCount,
        COALESCE(SUM(Votes.VoteTypeId = 3)::int, 0) AS DownVoteCount,
        COALESCE(SUM(Votes.VoteTypeId = 6)::int, 0) AS CloseVoteCount,
        COALESCE(SUM(Votes.VoteTypeId = 11)::int, 0) AS ReopenVoteCount,
        ROW_NUMBER() OVER (PARTITION BY Posts.OwnerUserId ORDER BY Posts.CreationDate DESC) AS Rank
    FROM Posts
    LEFT JOIN Comments ON Comments.PostId = Posts.Id
    LEFT JOIN Votes ON Votes.PostId = Posts.Id
    GROUP BY Posts.Id
), UserPostDetail AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        P.PostId,
        P.Title,
        P.CreationDate,
        P.CommentCount,
        P.UpVoteCount - P.DownVoteCount AS VoteBalance,
        UV.UpVotes AS UserUpVotes,
        UV.DownVotes AS UserDownVotes,
        CASE 
            WHEN P.CloseVoteCount > 0 THEN 'Closed'
            WHEN P.ReopenVoteCount > 0 THEN 'Reopened'
            ELSE 'Active'
        END AS Status
    FROM UserVoteStats AS UV
    FULL OUTER JOIN PostStats AS P ON UV.UserId = P.OwnerUserId
    FULL OUTER JOIN Users AS U ON U.Id = P.OwnerUserId
    WHERE (UV.UpVotes IS NOT NULL OR UV.DownVotes IS NOT NULL)
)

SELECT 
    DISTINCT U.DisplayName,
    U.PostId,
    U.Title,
    DATE_PART('year', U.CreationDate) AS CreationYear,
    U.CommentCount,
    U.VoteBalance,
    U.Status
FROM UserPostDetail AS U
WHERE U.VoteBalance <> 0
AND U.Status = 'Active'
AND (U.UserUpVotes IS NULL OR U.UserDownVotes IS NOT NULL)
ORDER BY U.VoteBalance DESC, U.CreationYear DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
