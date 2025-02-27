WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Considering only BountyStart and BountyClose votes
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Posts created in the last year
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        SUM(p.ViewCount) AS TotalPostViews,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
),
ActivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(ph.Id) AS EditCount,
        STRING_AGG(ph.Comment, '; ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= DATEADD(MONTH, -6, GETDATE()) -- Post history in the last six months
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.TotalBounty,
    ua.DisplayName,
    ua.Reputation,
    ua.TotalPostViews,
    ah.EditCount,
    ah.EditComments
FROM 
    RankedPosts rp
JOIN 
    UserActivity ua ON rp.OwnerUserId = ua.UserId
LEFT JOIN 
    ActivePostHistory ah ON rp.PostId = ah.PostId
WHERE 
    rp.PostRank <= 3 -- Top 3 posts per user based on score
ORDER BY 
    ua.Reputation DESC, rp.Score DESC;

