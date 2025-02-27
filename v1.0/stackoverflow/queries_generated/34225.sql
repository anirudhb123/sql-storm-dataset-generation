WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        CAST(p.Title AS VARCHAR(300)) AS FullTitle,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        CAST(CONCAT(rph.FullTitle, ' -> ', p.Title) AS VARCHAR(300)) AS FullTitle,
        rph.Level + 1
    FROM 
        Posts p
        JOIN RecursivePostHierarchy rph ON p.ParentId = rph.PostId
    WHERE 
        p.PostTypeId = 2 -- Answers
),
AggregatedVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass -- Get highest badge level for each user
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
ClosedPostsWithReasons AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) as CloseVoteCount,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
        JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened posts
    GROUP BY 
        ph.PostId
)
SELECT 
    rph.PostId,
    rph.FullTitle,
    a.UpVotes,
    a.DownVotes,
    ub.BadgeCount,
    ub.HighestBadgeClass,
    cp.CloseVoteCount,
    cp.CloseReasons
FROM 
    RecursivePostHierarchy rph
LEFT JOIN 
    AggregatedVotes a ON rph.PostId = a.PostId
LEFT JOIN 
    UserBadges ub ON rph.PostId IN (SELECT OwnerUserId FROM Posts WHERE Id = rph.PostId)
LEFT JOIN 
    ClosedPostsWithReasons cp ON rph.PostId = cp.PostId
WHERE 
    (a.UpVotes - a.DownVotes) > 5 -- filter for popular posts with score greater than 5
    AND ub.BadgeCount > 2 -- filter for users with more than 2 badges
ORDER BY 
    cp.CloseVoteCount DESC,
    a.UpVotes DESC;
