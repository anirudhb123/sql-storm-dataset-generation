WITH UserScores AS (
    SELECT 
        Id,
        Reputation,
        (UpVotes - DownVotes) AS NetVotes,
        CASE 
            WHEN Reputation = 0 THEN 'Newbie'
            WHEN Reputation < 100 THEN 'Novice'
            WHEN Reputation < 500 THEN 'Intermediate'
            ELSE 'Expert' 
        END AS UserLevel
    FROM Users
),
PostAnalysis AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(CLOSE_COMMENTS.CommentCount, 0) AS CloseCommentCount,
        COALESCE(OPEN_COMMENTS.CommentCount, 0) AS OpenCommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        (
            SELECT STRING_AGG(t.TagName, ', ' ORDER BY t.TagName)
            FROM Tags t
            WHERE t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[]))
        ) AS FormattedTags,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AnswerStatus
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) CLOSE_COMMENTS ON p.Id = CLOSE_COMMENTS.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        WHERE CreationDate > NOW() - INTERVAL '30 days'
        GROUP BY PostId
    ) OPEN_COMMENTS ON p.Id = OPEN_COMMENTS.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
VoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),
FinalAnalysis AS (
    SELECT 
        ua.Id AS UserId,
        ua.UserLevel,
        pa.PostId,
        pa.Title,
        pa.CreationDate,
        pa.Score,
        pa.CloseCommentCount,
        pa.OpenCommentCount,
        pa.FormattedTags,
        pa.AnswerStatus,
        COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
        COALESCE(vs.DownVotes, 0) AS TotalDownVotes,
        CASE 
            WHEN pa.Score > 0 AND vs.UpVotes > vs.DownVotes THEN 'Positive Engagement'
            WHEN pa.Score < 0 AND vs.DownVotes > vs.UpVotes THEN 'Negative Engagement'
            ELSE 'Neutral' 
        END AS EngagementType
    FROM UserScores ua
    JOIN PostAnalysis pa ON ua.Id = pa.OwnerUserId
    LEFT JOIN VoteStats vs ON pa.PostId = vs.PostId
)
SELECT 
    UserId,
    UserLevel,
    COUNT(PostId) AS TotalPosts,
    AVG(COALESCE(TotalUpVotes, 0) - COALESCE(TotalDownVotes, 0)) AS AvgVoteBalance,
    STRING_AGG(DISTINCT FormattedTags, '; ') AS AllTags,
    COUNT(CASE WHEN EngagementType = 'Positive Engagement' THEN 1 END) AS PositiveEngagementCount,
    COUNT(CASE WHEN EngagementType = 'Negative Engagement' THEN 1 END) AS NegativeEngagementCount
FROM FinalAnalysis
GROUP BY UserId, UserLevel
HAVING COUNT(PostId) > 5
ORDER BY TotalPosts DESC, AvgVoteBalance DESC
LIMIT 10;
