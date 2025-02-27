WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate) AS Version,
        ph.Comment,
        ph.UserId
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13) -- Focus on Post Closure actions
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.Comments,
        ub.BadgeCount
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHistory rph ON p.Id = rph.PostId
    LEFT JOIN 
        UserBadges ub ON p.OwnerUserId = ub.UserId
    WHERE 
        rph.Version = 1 -- Only get the initial closure information
        AND p.CreationDate >= '2022-01-01' -- Only consider posts created after 2022
),
RecentUserActivity AS (
    SELECT 
        u.DisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS UpvoteCount
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 2 -- Only Upvotes
    WHERE 
        u.Reputation > 1000 -- Only consider users with a reputation above 1000
    GROUP BY 
        u.DisplayName
)
SELECT 
    cp.PostId,
    cp.Title,
    cp.CreationDate,
    cp.Comments,
    cp.BadgeCount,
    rua.DisplayName,
    rua.CommentCount,
    rua.UpvoteCount
FROM 
    ClosedPosts cp
LEFT JOIN 
    RecentUserActivity rua ON cp.BadgeCount > 5 AND rua.CommentCount > 0 -- Users with >5 badges and at least one comment
ORDER BY 
    cp.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
