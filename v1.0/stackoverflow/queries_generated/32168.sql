WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11, 12) THEN 1 END) AS ClosureChanges,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (1, 4) THEN 1 END) AS TitleChanges,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserReputation AS (
    SELECT 
        Id AS UserId,
        SUM(Reputation) AS TotalReputation,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges B ON u.Id = B.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    pha.ClosureChanges,
    pha.TitleChanges,
    CASE 
        WHEN rp.CommentCount > 0 THEN (rp.Score / NULLIF(rp.CommentCount, 0)) 
        ELSE NULL 
    END AS ScorePerComment,
    ur.TotalReputation,
    ur.BadgeCount,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Latest Post of User'
        ELSE NULL
    END AS PostStatus
FROM 
    RankedPosts rp
JOIN 
    PostHistoryAggregates pha ON rp.PostId = pha.PostId
JOIN 
    Users owner ON rp.OwnerDisplayName = owner.DisplayName
JOIN 
    UserReputation ur ON owner.Id = ur.UserId
WHERE 
    rp.CommentCount > 5
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
