WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        p.CreationDate,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(JSON_AGG(DISTINCT pt.Name) FILTER (WHERE pt.Name IS NOT NULL), '[]') AS PostTypeNames,
        COALESCE(count(c.id), 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '30 days')
    GROUP BY 
        p.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ph.UserId,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed'
            ELSE 'Reopened'
        END AS ClosureType
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
   AND 
        ph.CreationDate >= (CURRENT_DATE - INTERVAL '30 days')
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
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Rank,
    rp.Reputation,
    rb.BadgeCount,
    rb.BadgeNames,
    COUNT(cp.PostId) AS ClosureCount,
    STRING_AGG(DISTINCT cp.ClosureType) AS ClosureStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    UserBadges rb ON rp.Reputation = rb.UserId
WHERE 
    rp.Rank <= 5
GROUP BY 
    rp.PostId, rp.Title, rp.OwnerDisplayName, rp.Rank, rp.Reputation, rb.BadgeCount, rb.BadgeNames
ORDER BY 
    rp.Rank, rp.Reputation DESC;

