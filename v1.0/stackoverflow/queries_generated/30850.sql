WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        0 AS Level,
        CAST(p.Title AS VARCHAR(MAX)) AS FullTitle
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        rp.Level + 1,
        CAST(rp.FullTitle + ' -> ' + p.Title AS VARCHAR(MAX))
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE rp ON p.ParentId = rp.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    rp.FullTitle,
    u.DisplayName,
    ub.BadgeCount,
    COALESCE(ps.UpVotes, 0) AS TotalUpVotes,
    COALESCE(ps.DownVotes, 0) AS TotalDownVotes,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT ph.Id) AS HistoryCount
FROM 
    RecursivePostCTE rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    Comments c ON rp.PostId = c.PostId
LEFT JOIN 
    PostVoteStats ps ON rp.PostId = ps.PostId
LEFT JOIN 
    PostHistory ph ON rp.PostId = ph.PostId
GROUP BY 
    rp.FullTitle, u.DisplayName, ub.BadgeCount, ps.UpVotes, ps.DownVotes
HAVING 
    ub.BadgeCount > 0 -- Only include users with at least one badge
ORDER BY 
    TotalUpVotes DESC, rp.CreationDate DESC
LIMIT 100;
