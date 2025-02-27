WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ParentId,
        p.PostTypeId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.ParentId, p.PostTypeId
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(*) AS TotalBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        ph.PostId
)
SELECT 
    up.Id AS UserId,
    up.DisplayName,
    up.Reputation,
    rp.PostId,
    rp.Title,
    COALESCE(upb.BadgeNames, 'No Badges') AS UserBadges,
    COALESCE(pgs.HistoryTypes, 'No Changes') AS PostHistoryTypes,
    COALESCE(rp.CommentCount, 0) AS CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rp.PostTypeId = 1 THEN 'Question'
        WHEN rp.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType,
    rp.CreationDate,
    CASE 
        WHEN rp.ParentId IS NOT NULL THEN 
            (SELECT Title FROM Posts WHERE Id = rp.ParentId)
        ELSE 
            'No Parent'
    END AS ParentPostTitle
FROM 
    Users up
JOIN 
    RankedPosts rp ON up.Id = rp.OwnerUserId
LEFT JOIN 
    UserBadges upb ON up.Id = upb.UserId
LEFT JOIN 
    PostHistorySummary pgs ON rp.PostId = pgs.PostId
WHERE 
    rp.PostRank <= 5
ORDER BY 
    up.Reputation DESC, rp.UpVotes DESC, rp.CreationDate DESC
LIMIT 100;

-- Testing with outer joins and NULL logic
SELECT 
    p.Id AS PostId,
    p.Title,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COALESCE(b.BadgeCount, 0) AS UserBadgeCount,
    CASE 
        WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) b ON p.OwnerUserId = b.UserId
WHERE 
    p.ViewCount > 100
GROUP BY 
    p.Id, p.Title, p.ClosedDate
HAVING 
    COUNT(DISTINCT c.Id) > 0 
    OR (b.BadgeCount IS NOT NULL AND b.BadgeCount > 0)
ORDER BY 
    p.CreationDate DESC
LIMIT 50;
