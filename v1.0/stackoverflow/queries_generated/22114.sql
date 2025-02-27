WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(NULLIF(p.Score, 0), NULL) AS EffectiveScore,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentCounts
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2022-01-01'
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        AVG(COALESCE(NULLIF(u.Reputation, 0), NULL)) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        AVG(COALESCE(NULLIF(u.Reputation, 0), NULL)) > 5000
)
SELECT 
    p.PostId,
    p.Title,
    p.ViewCount,
    p.EffectiveScore,
    ub.BadgeCount,
    ub.BadgeNames,
    phd.HistoryTypes,
    phd.FirstEditDate,
    phd.LastEditDate,
    t.TotalBounties,
    t.AverageReputation
FROM 
    RankedPosts p
LEFT JOIN 
    UserBadges ub ON p.OwnerUserId = ub.UserId
LEFT JOIN 
    PostHistoryDetails phd ON p.PostId = phd.PostId
LEFT JOIN 
    TopUsers t ON p.OwnerUserId = t.UserId
WHERE 
    p.CommentCounts > 5
ORDER BY 
    p.EffectiveScore DESC, 
    p.ViewCount DESC
LIMIT 100;
