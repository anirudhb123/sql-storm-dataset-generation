WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId IN (2, 4) THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),

UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1
    GROUP BY 
        b.UserId
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        COUNT(DISTINCT ph.UserId) AS ModifierCount,
        STRING_AGG(DISTINCT ph.UserDisplayName, ', ') AS Modifiers
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostDate,
    u.DisplayName AS Owner,
    ub.BadgeCount,
    ub.BadgeNames,
    rp.CommentCount,
    rp.Upvotes,
    rp.Downvotes,
    COALESCE(phd.ClosedDate, 'Not Closed') AS ClosedStatus,
    phd.ModifierCount,
    phd.Modifiers
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.RowNum <= 10
ORDER BY 
    rp.CreationDate DESC;

WITH PotentialIssues AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        CASE 
            WHEN p.ViewCount IS NULL THEN 'NO VIEWS RECORDED'
            WHEN p.ViewCount < 10 THEN 'LOW AWARENESS'
            ELSE 'NORMAL'
        END AS AwarenessStatus,
        ROUND((COALESCE(rp.Upvotes, 0) - COALESCE(rp.Downvotes, 0))::numeric / NULLIF(p.ViewCount, 0) * 100, 2) AS EngagementRate
    FROM 
        Posts p
    LEFT JOIN 
        RankedPosts rp ON p.Id = rp.PostId
)
SELECT 
    pi.PostId,
    pi.Title,
    pi.AwarenessStatus,
    pi.EngagementRate
FROM 
    PotentialIssues pi
WHERE 
    pi.EngagementRate IS NOT NULL
    AND pi.AwarenessStatus = 'LOW AWARENESS'
ORDER BY 
    pi.EngagementRate DESC;

WITH RecentPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.CreationDate,
        COUNT(c.Id) AS TotalComments,
        COUNT(DISTINCT u.Id) AS UniqueCommenters
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON c.UserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.CreationDate
)
SELECT 
    rps.PostId,
    rps.CreationDate,
    rps.TotalComments,
    rps.UniqueCommenters,
    CASE 
        WHEN rps.UniqueCommenters = 0 THEN 'No comments made yet'
        ELSE CONCAT(rps.UniqueCommenters, ' unique commenters engaged.')
    END AS CommentEngagement
FROM 
    RecentPostStats rps
WHERE 
    rps.TotalComments > 0
ORDER BY 
    rps.TotalComments DESC;
