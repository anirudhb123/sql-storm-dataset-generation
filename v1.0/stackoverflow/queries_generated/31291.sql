WITH RecursiveCTE AS (
    -- Retrieve all posts and their related posts
    SELECT 
        p.Id AS PostId,
        p.Title,
        pl.RelatedPostId,
        1 AS Level
    FROM 
        Posts p
    JOIN 
        PostLinks pl ON p.Id = pl.PostId

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        pl.RelatedPostId,
        r.Level + 1
    FROM 
        Posts p
    JOIN 
        PostLinks pl ON p.Id = pl.RelatedPostId
    JOIN 
        RecursiveCTE r ON pl.PostId = r.PostId
),
PostVoteCounts AS (
    -- Calculate the vote counts per post
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
    -- Get the number of badges per user
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        MAX(Class) AS HighestBadge
    FROM 
        Badges
    GROUP BY 
        UserId
),
RecentPosts AS (
    -- Retrieve recent posts by users who have at least one badge
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        u.DisplayName,
        ub.BadgeCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        ub.BadgeCount IS NOT NULL  -- Users with at least one badge
        AND p.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.DisplayName,
    COALESCE(pvc.UpVotes, 0) AS UpVotes,
    COALESCE(pvc.DownVotes, 0) AS DownVotes,
    rb.RelatedPostId AS RelatedPostId,
    rb.Level,
    ub.BadgeCount AS UserBadgeCount
FROM 
    RecentPosts rp
LEFT JOIN 
    PostVoteCounts pvc ON rp.PostId = pvc.PostId
LEFT JOIN 
    RecursiveCTE rb ON rp.PostId = rb.PostId
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.BadgeCount >= 1 -- Only include users with at least one badge
ORDER BY 
    rp.CreationDate DESC, 
    UpVotes DESC;
