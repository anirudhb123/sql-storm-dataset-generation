WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        p.LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.Score > 0 AND 
        p.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT ph.PostId) AS TotalPostHistoryChanges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8 -- BountyStart
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    GROUP BY 
        u.Id
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, '<>')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Post Closed, Post Reopened
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserId,
    up.DisplayName,
    COALESCE(rp.Title, 'No Posts Found') AS RecentPostTitle,
    COALESCE(CAST(pr.Tags AS VARCHAR), 'No Tags') AS PostTags,
    us.TotalBounty,
    us.BadgeCount,
    COALESCE(cp.FirstClosedDate, NULL) AS FirstClosedDate,
    DENSE_RANK() OVER (ORDER BY us.TotalBounty DESC) AS BountyRank
FROM 
    UserStats us
JOIN 
    Users up ON us.UserId = up.Id
LEFT JOIN 
    RankedPosts rp ON rp.OwnerUserId = us.UserId AND rp.rn = 1
LEFT JOIN 
    PostTags pr ON pr.PostId = GETDATE() -- Assuming we use current datetime for filtering
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = COALESCE(rp.Id, -1) 
WHERE 
    us.TotalPostHistoryChanges > 0
ORDER BY 
    us.TotalBounty DESC, 
    us.BadgeCount DESC;
