
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        @rownum := IF(@prevPostType = p.PostTypeId, @rownum + 1, 1) AS PostRank,
        @prevPostType := p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8,
        (SELECT @rownum := 0, @prevPostType := NULL) r
    WHERE 
        p.CreationDate >= '2023-10-01 12:34:56'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.PostTypeId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT pht.Name SEPARATOR '; ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.PostRank,
    rp.CommentCount,
    COALESCE(ub.BadgeNames, 'No Badges') AS UserBadges,
    ub.BadgeCount,
    COALESCE(phd.HistoryTypes, 'No History') AS PostHistory,
    phd.LastHistoryDate,
    CASE 
        WHEN rp.AverageBounty IS NULL THEN 'No Bounty' 
        ELSE CONCAT('Avg Bounty: $', rp.AverageBounty) 
    END AS BountySummary
FROM 
    RankedPosts rp
LEFT JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
