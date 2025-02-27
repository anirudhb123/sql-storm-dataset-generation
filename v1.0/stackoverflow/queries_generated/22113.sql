WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        CASE 
            WHEN Reputation < 100 THEN 'Newbie' 
            WHEN Reputation BETWEEN 100 AND 1000 THEN 'Enthusiast' 
            ELSE 'Expert' 
        END AS ReputationLevel
    FROM Users
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes, -- Counting Upvotes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes, -- Counting Downvotes
        COUNT(c.Id) AS CommentCount, -- Total Comments
        COUNT(DISTINCT pl.RelatedPostId) AS LinkedPosts -- Total Linked Posts
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year' -- Filtering for posts in the last year
    GROUP BY p.Id
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- Count of posts closed
    GROUP BY ph.PostId
), 
PostSummary AS (
    SELECT 
        ps.PostId,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        COALESCE(cp.CloseCount, 0) AS CloseCount 
    FROM PostStats ps
    LEFT JOIN ClosedPosts cp ON ps.PostId = cp.PostId
), 
OverallRankedPosts AS (
    SELECT 
        p.Title,
        p.CreationDate,
        ps.UpVotes - ps.DownVotes AS NetVotes,
        ps.CommentCount,
        ps.CloseCount,
        RANK() OVER (ORDER BY (ps.UpVotes - ps.DownVotes) DESC, ps.CommentCount DESC) AS PostRank
    FROM Posts p
    JOIN PostSummary ps ON p.Id = ps.PostId
    WHERE p.PostTypeId = 1 -- Focusing on questions only
)

SELECT 
    ur.DisplayName, 
    ur.ReputationLevel, 
    orp.Title, 
    orp.CreationDate,
    orp.NetVotes,
    orp.CommentCount,
    CASE 
        WHEN orp.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM OverallRankedPosts orp
JOIN Users ur ON ur.Id = (SELECT OwnerUserId FROM Posts WHERE Id = orp.PostId)
WHERE orp.PostRank <= 10 -- Top 10 posts by rank
ORDER BY orp.NetVotes DESC, ur.ReputationLevel DESC;
