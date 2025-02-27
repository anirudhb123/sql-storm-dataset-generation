WITH RecursivePostHierarchy AS (
    -- Recursive CTE to get post and its accepted answers
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.AcceptedAnswerId, 
        0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        p2.Id AS PostId, 
        p2.Title, 
        p2.AcceptedAnswerId, 
        Level + 1
    FROM Posts p2
    JOIN RecursivePostHierarchy r ON p2.ParentId = r.PostId
    WHERE p2.PostTypeId = 2  -- Only answers
),

PostVoteSummary AS (
    -- Aggregate votes by post
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),

UserBadges AS (
    -- Get the count of badges per user
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),

PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.UpVotes,
        ph.DownVotes,
        COALESCE(ub.BadgeCount, 0) AS UserBadgeCount
    FROM Posts p
    LEFT JOIN PostVoteSummary ph ON p.Id = ph.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    WHERE p.CreationDate > CURRENT_DATE - INTERVAL '1 year'  -- Posts from the last year
),

ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.RevisionGUID, 
        ph.CreationDate, 
        MIN(ph.CreationDate) AS FirstCloseDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10  -- Closed posts
    GROUP BY ph.PostId, ph.RevisionGUID, ph.CreationDate
)

-- Final Selection Query
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.UpVotes,
    pd.DownVotes,
    COALESCE(cp.FirstCloseDate, 'Not Closed') AS FirstCloseDate,
    pd.UserBadgeCount,
    COUNT(DISTINCT r.PostId) AS AcceptedAnswerCount
FROM PostDetails pd
LEFT JOIN ClosedPosts cp ON pd.PostId = cp.PostId
LEFT JOIN RecursivePostHierarchy r ON pd.PostId = r.PostId
WHERE 
    pd.UpVotes > 5  -- Only considering posts with more than 5 upvotes
GROUP BY 
    pd.PostId, pd.Title, pd.CreationDate, pd.UpVotes, pd.DownVotes, cp.FirstCloseDate, pd.UserBadgeCount
ORDER BY 
    pd.UpVotes DESC, pd.CreationDate DESC;

