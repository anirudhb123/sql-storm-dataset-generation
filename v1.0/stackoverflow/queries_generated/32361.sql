WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.AnswerCount,
    rp.Score,
    COALESCE(cp.FirstClosedDate, 'Not Closed') AS FirstClosedDate,
    COALESCE(ub.BadgeCount, 0) AS NumberOfBadges,
    CASE 
        WHEN ub.HighestBadgeClass = 1 THEN 'Gold'
        WHEN ub.HighestBadgeClass = 2 THEN 'Silver'
        WHEN ub.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'No Badge'
    END AS HighestBadge
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
LEFT JOIN 
    UserBadges ub ON rp.OwnerDisplayName = ub.UserId
WHERE 
    rp.ScoreRank <= 10 -- Fetch top 10 scored questions
    AND (rp.CreationDate >= DATEADD(year, -1, GETDATE()) OR cp.FirstClosedDate IS NOT NULL) -- Questions from the last year or already closed
ORDER BY 
    rp.Score DESC;
