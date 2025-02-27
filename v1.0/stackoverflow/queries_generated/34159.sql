WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        1 as Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostVoteStats AS (
    SELECT 
        p.Id as PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) as UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) as DownVotes,
        COUNT(v.Id) as TotalVotes,
        COALESCE(AVG(v.BountyAmount), 0) as AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostHistoryChanges AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) as LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) as LastReopenedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11, 12) THEN 1 END) as ClosureCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserBadgeStats AS (
    SELECT 
        u.Id as UserId,
        COUNT(b.Id) as BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) as GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) as SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) as BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    p.Id as PostId,
    p.Title,
    p.CreationDate,
    CONCAT(u.DisplayName, ' (ID: ', u.Id, ')') as Owner,
    COALESCE(pv.UpVotes, 0) as UpVotes,
    COALESCE(pv.DownVotes, 0) as DownVotes,
    COALESCE(ph.LastClosedDate, ph.LastReopenedDate) as MostRecentClosureOrReopening,
    us.BadgeCount as UserBadgeCount,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    r.Level as PostHierarchyLevel
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostVoteStats pv ON p.Id = pv.PostId
LEFT JOIN 
    PostHistoryChanges ph ON p.Id = ph.PostId
LEFT JOIN 
    UserBadgeStats us ON u.Id = us.UserId
JOIN 
    RecursivePostHierarchy r ON p.Id = r.Id
ORDER BY 
    p.CreationDate DESC,
    pv.UpVotes DESC;
