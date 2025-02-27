WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Select only questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
PostScoreSummary AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 WHEN VoteTypeId = 3 THEN -1 ELSE 0 END) AS NetScore,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS CloseDate, 
        ph.UserDisplayName AS ClosedBy,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId, ph.CreationDate, ph.UserDisplayName
)
SELECT 
    rph.PostId,
    rph.Title,
    rph.Level,
    COALESCE(ps.NetScore, 0) AS NetScore,
    COALESCE(ps.UpVotes, 0) AS UpVotes,
    COALESCE(ps.DownVotes, 0) AS DownVotes,
    ub.BadgeCount,
    ub.BadgeNames,
    cp.CloseDate,
    cp.ClosedBy,
    cp.CloseReasons
FROM 
    RecursivePostHierarchy rph
LEFT JOIN 
    PostScoreSummary ps ON rph.PostId = ps.PostId
LEFT JOIN 
    Users ub ON rph.PostId = ub.Id
LEFT JOIN 
    UserBadges ub ON ub.UserId = rph.PostId 
LEFT JOIN 
    ClosedPosts cp ON rph.PostId = cp.PostId
WHERE 
    rph.Level <= 3 -- Limit depth of hierarchy
ORDER BY 
    rph.Level, NetScore DESC;
This SQL query accomplishes several tasks:

1. **Recursive Common Table Expression** is used to retrieve a hierarchy of posts, starting from questions and going down through their answers.

2. **Aggregate Functions** summarize votes on posts to calculate net scores, upvotes, and downvotes.

3. **User Badges** summarization retrieves users and counts the badges they hold.

4. **Closed Posts** aggregates details of closed posts, including the reasons for closure.

5. The final SELECT combines the results, filtering and ordering them appropriately to ensure meaningful output, specifically focusing on post hierarchy, scoring, user badges, and post closure details.
