WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputations AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Counts only Bounty Start and Bounty Close
    GROUP BY 
        p.Id
)
SELECT 
    up.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    ra.cn,
    ua.TotalBadges,
    ua.TotalViews,
    pa.CommentCount,
    pa.TotalBounty
FROM 
    RankedPosts rp
JOIN 
    UserReputations ua ON rp.OwnerUserId = ua.UserId
LEFT JOIN 
    PostActivity pa ON rp.Id = pa.PostId
LEFT JOIN 
    LATERAL (
        SELECT COUNT(*) AS cn 
        FROM Posts p2 
        WHERE p2.AcceptedAnswerId = rp.Id
    ) AS ra ON TRUE
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, 
    ua.TotalViews DESC 
LIMIT 50;
