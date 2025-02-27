WITH RecursiveUserPosts AS (
    -- CTE to get the post and user details recursively
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        u.Reputation AS UserReputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation >= 1000   -- Only including users with reputation >= 1000
    
    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        u.Reputation
    FROM 
        Posts p
    INNER JOIN 
        RecursiveUserPosts r ON p.ParentId = r.PostId
    JOIN 
        Users u ON r.OwnerUserId = u.Id
),

PostVoteCounts AS (
    -- CTE to count votes on posts
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),

ClosedPostReasons AS (
    -- CTE to aggregate close reasons for closed posts
    SELECT 
        p.Id AS PostId,
        STRING_AGG(DISTINCT c.Name, ', ') AS CloseReasonNames
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    JOIN 
        CloseReasonTypes c ON ph.Comment::int = c.Id
    WHERE 
        ph.PostHistoryTypeId = 10  -- Only considering closed posts
    GROUP BY 
        p.Id
),

UserBadges AS (
    -- CTE to get badge information for users
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.UserReputation,
    COALESCE(vc.UpVotes, 0) AS UpVoteCount,
    COALESCE(vc.DownVotes, 0) AS DownVoteCount,
    COALESCE(cr.CloseReasonNames, 'Not Closed') AS CloseReasons,
    ub.BadgeCount
FROM 
    RecursiveUserPosts r
LEFT JOIN 
    PostVoteCounts vc ON r.PostId = vc.PostId
LEFT JOIN 
    ClosedPostReasons cr ON r.PostId = cr.PostId
LEFT JOIN 
    UserBadges ub ON r.OwnerUserId = ub.UserId
ORDER BY 
    r.Score DESC, r.CreationDate ASC
LIMIT 100;

