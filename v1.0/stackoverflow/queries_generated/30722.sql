WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
    
    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        Level + 1
    FROM 
        Posts p
    INNER JOIN RecursivePostCTE r ON p.ParentId = r.PostId
),
PostVoteStats AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Votes v
    INNER JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    r.PostId,
    r.Title,
    COALESCE(pvs.UpVotes, 0) AS UpVotes, 
    COALESCE(pvs.DownVotes, 0) AS DownVotes,
    COALESCE(ub.BadgeCount, 0) as UserBadgeCount,
    ub.HighestBadgeClass,
    r.CreationDate,
    r.LastActivityDate,
    r.ViewCount,
    r.Score,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    RecursivePostCTE r
LEFT JOIN PostVoteStats pvs ON r.PostId = pvs.PostId
LEFT JOIN Users u ON r.OwnerUserId = u.Id
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN LATERAL (
    SELECT 
        NULLIF(TRIM(UNNEST(string_to_array(r.Tags, ','))), '') AS TagName
    FROM 
        Posts p
    WHERE 
        p.Id = r.PostId
) t ON true
LEFT JOIN Tags tg ON t.TagName = tg.TagName
WHERE 
    r.ViewCount > 100 AND
    r.LastActivityDate >= NOW() - INTERVAL '30 days'
GROUP BY 
    r.PostId, u.Id, ub.BadgeCount, ub.HighestBadgeClass
ORDER BY 
    r.Score DESC, r.LastActivityDate DESC;
