WITH RecursivePostHistory AS (
    SELECT 
        ph.Id,
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        ph.Text,
        1 AS Level
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Only considering closing and reopening events for recursion

    UNION ALL

    SELECT 
        ph.Id,
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        ph.Text,
        r.Level + 1
    FROM 
        PostHistory ph
    INNER JOIN 
        RecursivePostHistory r ON ph.PostId = r.PostId AND ph.CreationDate < r.CreationDate
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Recursive condition to track closes and reopens
),

UserRankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(v.Id) DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
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
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ub.BadgeNames, 'No Badges') AS Badges,
    up.Title AS MostVotedPost,
    up.VoteCount AS MostVotedCount,
    rph.CreationDate AS LastCloseOrReopenDate,
    rph.UserDisplayName AS ActionedBy
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    UserRankedPosts up ON u.Id = up.OwnerUserId AND up.UserPostRank = 1
LEFT JOIN 
    (
        SELECT 
            PostId,
            MAX(CreationDate) AS CreationDate,
            UserDisplayName
        FROM 
            RecursivePostHistory
        GROUP BY 
            PostId, UserDisplayName
    ) rph ON up.Id = rph.PostId
WHERE 
    u.Reputation > 100 -- Considering only users with reputation above 100
ORDER BY 
    u.Reputation DESC, 
    TotalBadges DESC;
