WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id, u.Reputation
),
PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ur.Reputation,
        ur.BadgeCount,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON rp.PostId = c.PostId
    WHERE 
        rp.Rank <= 3 
)
SELECT 
    ps.*,
    CASE 
        WHEN ps.BadgeCount > 0 THEN 'Has Badges' 
        ELSE 'No Badges' 
    END AS BadgeStatus,
    CASE 
        WHEN ps.Reputation > 1000 THEN 'High Reputation' 
        ELSE 'Low Reputation' 
    END AS ReputationStatus
FROM 
    PostSummary ps
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;

-- Extra: Finding posts linked to other posts that contain 'SQL' in the title
SELECT 
    pl.PostId,
    p.Title AS LinkedPostTitle,
    p.ViewCount AS LinkedPostViewCount
FROM 
    PostLinks pl
JOIN 
    Posts p ON pl.RelatedPostId = p.Id
WHERE 
    p.Title ILIKE '%SQL%'
ORDER BY 
    LinkedPostViewCount DESC;
