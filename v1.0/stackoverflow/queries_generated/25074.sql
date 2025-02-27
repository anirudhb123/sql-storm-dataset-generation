WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostMetrics AS (
    SELECT 
        p.PostId,
        rp.Title,
        rp.RankByViews,
        ur.DisplayName AS OwnerName,
        ur.Reputation,
        ur.BadgeCount,
        p.ViewCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.PostId AND v.VoteTypeId = 2) AS UpVoteCount
    FROM 
        RankedPosts p
    JOIN 
        UserReputation ur ON p.OwnerUserId = ur.UserId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.OwnerName,
    pm.Reputation,
    pm.BadgeCount,
    pm.ViewCount,
    pm.CommentCount,
    pm.UpVoteCount,
    CASE 
        WHEN pm.RankByViews < 4 THEN 'Low Visibility'
        WHEN pm.RankByViews BETWEEN 4 AND 10 THEN 'Moderate Visibility'
        ELSE 'High Visibility'
    END AS VisibilityCategory
FROM 
    PostMetrics pm
WHERE 
    pm.RankByViews <= 10
ORDER BY 
    pm.ViewCount DESC, 
    pm.BadgeCount DESC;
