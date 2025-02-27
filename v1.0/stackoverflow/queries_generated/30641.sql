WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.ParentId,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
RecentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        NULLIF(u.Location, '') AS Location,
        RANK() OVER (ORDER BY u.CreationDate DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '30 days'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    rpc.Title AS RecentPostTitle,
    rpc.AnswerCount,
    rb.BadgeCount,
    rb.BadgeNames,
    rpu.UserPostRank,
    rpu.CreationDate AS PostCreationDate
FROM 
    RecentUsers u
LEFT JOIN 
    RecursivePostCTE rpc ON u.Id = rpc.OwnerUserId
LEFT JOIN 
    UserBadges rb ON u.Id = rb.UserId
LEFT JOIN 
    (
        SELECT 
            r.Id,
            r.UserId,
            r.Title,
            r.CreationDate
        FROM 
            RecursivePostCTE r
        WHERE 
            r.AnswerCount > 0
    ) rpu ON u.Id = rpu.UserId
WHERE 
    rb.BadgeCount > 0 
    OR rpu.UserPostRank IS NOT NULL
ORDER BY 
    u.Reputation DESC, 
    rpc.CreationDate DESC
FETCH FIRST 10 ROWS ONLY;

-- This query performs complex operations such as:
-- 1. CTEs to recursively gather post hierarchy information and rank users based on recent activity.
-- 2. Aggregation to count user badges and concatenate their names.
-- 3. It combines multiple outer joins to compile relevant user data based on recent activity and received badges.
-- 4. Filters for users with at least one badge or recent post activity, sorted by user reputation.
