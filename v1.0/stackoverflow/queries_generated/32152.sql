WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.PostTypeId,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions
    UNION ALL
    SELECT 
        p2.Id AS PostId,
        p2.Title,
        p2.OwnerUserId,
        p2.CreationDate,
        p2.PostTypeId,
        p2.ParentId,
        r.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostCTE r ON p2.ParentId = r.PostId
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'  -- Filter for this year
    GROUP BY 
        p.Id
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
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
    u.Reputation,
    us.BadgeCount,
    us.HighestBadgeClass,
    pvs.UpVotes,
    pvs.DownVotes,
    pvs.TotalVotes
FROM 
    RecursivePostCTE r
JOIN 
    Users u ON r.OwnerUserId = u.Id
JOIN 
    UserBadges us ON u.Id = us.UserId
JOIN 
    PostVoteSummary pvs ON r.PostId = pvs.PostId
LEFT JOIN 
    CloseReasonTypes c ON r.PostTypeId = 10 -- Closing reasons for closed posts
WHERE 
    us.BadgeCount > 0 AND  -- Users with badges
    (pvs.UpVotes - pvs.DownVotes) > 10 AND  -- Engagement threshold
    (r.Level <= 1 OR r.ParentId IS NULL)  -- Main questions only
ORDER BY 
    r.CreationDate DESC;
