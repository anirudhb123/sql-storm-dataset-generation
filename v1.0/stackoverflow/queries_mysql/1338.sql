
WITH UserReputation AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        Users.Reputation,
        @row_number := @row_number + 1 AS ReputationRank
    FROM Users, (SELECT @row_number := 0) AS init
    ORDER BY Users.Reputation DESC
),
PostStatistics AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.OwnerUserId,
        COUNT(Comments.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN Votes.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN Votes.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(DISTINCT CASE WHEN VoteTypes.Name = 'AcceptedByOriginator' THEN Votes.Id END) AS AcceptedVotes
    FROM Posts
    LEFT JOIN Comments ON Posts.Id = Comments.PostId
    LEFT JOIN Votes ON Posts.Id = Votes.PostId
    LEFT JOIN VoteTypes ON Votes.VoteTypeId = VoteTypes.Id
    GROUP BY Posts.Id, Posts.OwnerUserId
),
ClosedPostStats AS (
    SELECT 
        PostId,
        COUNT(*) AS CloseCount
    FROM PostHistory
    WHERE PostHistoryTypeId = 10
    GROUP BY PostId
),
FinalStatistics AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(p.CommentCount, 0) AS TotalComments,
        COALESCE(p.UpVoteCount, 0) AS TotalUpVotes,
        COALESCE(p.DownVoteCount, 0) AS TotalDownVotes,
        COALESCE(c.CloseCount, 0) AS TotalClosedPosts,
        @comments_rank := IF(@current_user = u.UserId, @comments_rank + 1, 1) AS CommentsRank,
        @current_user := u.UserId
    FROM UserReputation u, (SELECT @comments_rank := 0, @current_user := NULL) AS init
    LEFT JOIN PostStatistics p ON u.UserId = p.OwnerUserId
    LEFT JOIN ClosedPostStats c ON p.PostId = c.PostId
    ORDER BY u.UserId, COALESCE(p.CommentCount, 0) DESC
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    TotalClosedPosts,
    CommentsRank
FROM FinalStatistics
WHERE Reputation >= 100 
AND (TotalUpVotes > TotalDownVotes OR TotalClosedPosts > 0)
ORDER BY Reputation DESC, TotalUpVotes DESC;
