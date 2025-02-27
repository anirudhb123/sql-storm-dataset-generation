WITH RECURSIVE UserScoreCTE AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(p.Id) AS PostsCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
), 
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        CreationDate,
        UpVotes - DownVotes AS NetVotes,
        PostsCount,
        RANK() OVER (ORDER BY UpVotes DESC) AS VoteRank
    FROM UserScoreCTE
),
ClosedPostInfo AS (
    SELECT 
        h.UserDisplayName,
        h.CreationDate,
        COUNT(h.Id) AS ClosedPostsCount,
        STRING_AGG(DISTINCT pt.Name, ', ') AS CloseReasons
    FROM PostHistory h
    JOIN CloseReasonTypes pt ON h.Comment::int = pt.Id
    WHERE h.PostHistoryTypeId IN (10, 11) -- Closed and Reopened posts
    GROUP BY h.UserDisplayName, h.CreationDate
),
UserEngagement AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        u.NetVotes,
        COALESCE(c.ClosedPostsCount, 0) AS ClosedPostsCount,
        c.CloseReasons
    FROM RankedUsers u
    LEFT JOIN ClosedPostInfo c ON u.DisplayName = c.UserDisplayName
)
SELECT 
    ue.DisplayName,
    ue.NetVotes,
    ue.ClosedPostsCount,
    ue.CloseReasons,
    ROUND(ue.NetVotes::numeric / NULLIF(ue.ClosedPostsCount, 0), 2) AS VotesPerClosedPostRatio
FROM UserEngagement ue
WHERE ue.NetVotes > 0
ORDER BY VotesPerClosedPostRatio DESC
LIMIT 10;

