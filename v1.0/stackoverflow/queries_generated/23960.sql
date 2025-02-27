WITH RankedPosts AS (
    SELECT
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        Posts.Score,
        Posts.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY Posts.OwnerUserId ORDER BY Posts.CreationDate DESC) AS PostRank,
        COALESCE((SELECT COUNT(*) FROM Comments WHERE PostId = Posts.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes WHERE PostId = Posts.Id AND VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE((SELECT COUNT(*) FROM Votes WHERE PostId = Posts.Id AND VoteTypeId = 3), 0) AS DownVoteCount
    FROM Posts
    WHERE Posts.PostTypeId = 1 -- Questions only
), UserEngagement AS (
    SELECT
        Users.Id AS UserId,
        Users.DisplayName,
        Users.Reputation,
        SUM(RankedPosts.ViewCount) AS TotalViews,
        SUM(RankedPosts.CommentCount) AS TotalComments,
        SUM(RankedPosts.UpVoteCount) AS TotalUpVotes,
        SUM(RankedPosts.DownVoteCount) AS TotalDownVotes,
        COUNT(RankedPosts.PostId) AS QuestionCount
    FROM Users
    LEFT JOIN RankedPosts ON Users.Id = RankedPosts.OwnerUserId
    GROUP BY Users.Id, Users.DisplayName, Users.Reputation
), EngagementMetrics AS (
    SELECT
        *,
        CASE 
            WHEN QuestionCount = 0 THEN 0 
            ELSE (TotalUpVotes - TotalDownVotes) / QuestionCount 
        END AS NetVoteScore,
        CASE 
            WHEN TotalViews = 0 THEN 0 
            ELSE TotalComments::decimal / TotalViews * 100 
        END AS CommentEngagementPercentage
    FROM UserEngagement
), HighEngagementUsers AS (
    SELECT 
        *,
        NTILE(5) OVER (ORDER BY NetVoteScore DESC) AS NetVoteBucket,
        NTILE(5) OVER (ORDER BY CommentEngagementPercentage DESC) AS CommentBucket
    FROM EngagementMetrics
    WHERE Reputation > 100 -- focusing on well-established users
)
SELECT 
    Users.DisplayName, 
    MAX(COALESCE(EngagementMetrics.NetVoteScore, 0)) AS WorstNetVoteScore,
    MIN(COALESCE(EngagementMetrics.CommentEngagementPercentage, 0)) AS BestCommentEngagementPercentage,
    STRING_AGG(Posts.Title, '; ') AS PostsTitles,
    COUNT(Posts.Id) FILTER (WHERE Posts.CreationDate > NOW() - INTERVAL '1 month') AS RecentPostsCount,
    CASE 
        WHEN COUNT(Posts.Id) < 3 THEN 'Under-engaged'
        ELSE 'Engaged'
    END AS EngagementStatus
FROM HighEngagementUsers
LEFT JOIN Posts ON Posts.OwnerUserId = HighEngagementUsers.UserId
WHERE (HighEngagementUsers.NetVoteBucket = 5 OR HighEngagementUsers.CommentBucket = 1)
GROUP BY Users.DisplayName
HAVING MAX(COALESCE(EngagementMetrics.NetVoteScore, 0)) IS NOT NULL
ORDER BY WorstNetVoteScore DESC
LIMIT 10;
