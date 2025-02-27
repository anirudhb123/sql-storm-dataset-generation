WITH RecursiveTagCounts AS (
    SELECT Tags.TagName, COUNT(PostId) AS PostCount
    FROM Tags
    JOIN Posts ON Tags.Id = Posts.TagId
    WHERE Tags.IsModeratorOnly = 0
    GROUP BY Tags.TagName
),
ActiveUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation, 
           RANK() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
    WHERE u.LastAccessDate > DATEADD(MONTH, -6, GETDATE())
),
ClosedPostDetails AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, 
           ph.CreationDate AS ClosureDate, ph.Comment AS CloseReason
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10
),
UserInteractions AS (
    SELECT u.Id AS UserId, COUNT(v.Id) AS VoteCount, SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
FinalRanking AS (
    SELECT a.Id AS UserId, a.DisplayName, a.Reputation,
           COALESCE(COUNT(DISTINCT ph.PostId), 0) AS ClosedPostCount,
           COALESCE(u.VoteCount, 0) AS TotalVotes,
           COALESCE(u.UpVoteCount, 0) AS TotalUpVotes,
           ROW_NUMBER() OVER (ORDER BY a.Reputation DESC) AS UserRank
    FROM ActiveUsers a
    LEFT JOIN ClosedPostDetails ph ON a.Id = ph.UserId
    LEFT JOIN UserInteractions u ON a.Id = u.UserId
    GROUP BY a.Id, a.DisplayName, a.Reputation
)
SELECT fr.UserRank, fr.DisplayName, fr.Reputation, 
       fr.ClosedPostCount, fr.TotalVotes, fr.TotalUpVotes,
       CASE WHEN fr.TotalVotes > 100 THEN 'High Engagement' ELSE 'Low Engagement' END AS EngagementLevel
FROM FinalRanking fr
JOIN RecursiveTagCounts rtc ON fr.ClosedPostCount > 0
ORDER BY fr.UserRank
OPTION (MAXRECURSION 2);
