WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 1) AS QuestionCount,
        COUNT(DISTINCT P.Id) FILTER (WHERE P.PostTypeId = 2) AS AnswerCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Posts P ON V.PostId = P.Id
    GROUP BY U.Id, U.DisplayName
),
RecentPostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentRank,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate > (NOW() - INTERVAL '30 days')
    GROUP BY P.Id, P.Title, P.OwnerUserId
),
PostCloseReasons AS (
    SELECT 
        PH.PostId,
        STRING_AGG(CRT.Name, ', ' ORDER BY CRT.Id) AS CloseReasonNames,
        COUNT(*) AS CloseCount
    FROM PostHistory PH
    JOIN CloseReasonTypes CRT ON PH.Comment::int = CRT.Id
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.PostId
),
MostActiveUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        RANK() OVER (ORDER BY SUM(UV.TotalBounty) DESC) AS UserRank,
        SUM(UV.UpVotes - UV.DownVotes) AS NetVotes
    FROM UserVoteStats UV
    JOIN Users U ON U.Id = UV.UserId
    GROUP BY U.Id, U.DisplayName
    HAVING SUM(UV.UpVotes - UV.DownVotes) > 0
)
SELECT 
    U.DisplayName AS User,
    U.Reputation AS UserReputation,
    RPA.Title AS RecentPostTitle,
    RPA.CommentCount AS TotalCommentsOnRecentPost,
    PCR.CloseReasonNames AS ReasonForClosure,
    MA.UserRank,
    MA.NetVotes
FROM Users U
JOIN RecentPostActivity RPA ON U.Id = RPA.OwnerUserId
LEFT JOIN PostCloseReasons PCR ON RPA.PostId = PCR.PostId
JOIN MostActiveUsers MA ON U.Id = MA.Id
WHERE MA.UserRank <= 10
ORDER BY MA.NetVotes DESC, U.Reputation DESC;

This complex SQL query includes multiple Common Table Expressions (CTEs) to accomplish several tasks:

1. `UserVoteStats`: Aggregates vote statistics for each user, including the count of upvotes and downvotes on their posts and total bounties earned.
2. `RecentPostActivity`: Fetches the most recent posts from users within the last 30 days, ranks them, and counts comments associated with those posts.
3. `PostCloseReasons`: Aggregates close reason names for posts that were closed based on the history records.
4. `MostActiveUsers`: Ranks users based on net votes (upvotes minus downvotes) and includes a filter to display only users with positive net votes.

Lastly, the main query combines results from these CTEs to display the users, their recent post details, the reasons for post closures, and ranks based on their activity, limited to the top 10 active users, sorted by net votes and reputation.
