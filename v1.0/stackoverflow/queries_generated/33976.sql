WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.OwnerUserId, 
        p.CreationDate, 
        p.Score, 
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
        AND p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Only posts from the last year
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
CloseReasonDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS Reasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id -- Assuming Comment stores reason ids as integers
    WHERE 
        ph.PostHistoryTypeId = 10 -- Only considering post closures
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS Author,
    vb.BadgeCount AS TotalBadges,
    vb.GoldBadges,
    vb.SilverBadges,
    vb.BronzeBadges,
    COALESCE(crd.Reasons, 'No reasons provided') AS CloseReasons,
    rp.Rank,
    p.Score,
    p.ViewCount
FROM 
    RankedPosts rp
JOIN 
    Posts p ON rp.Id = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges vb ON u.Id = vb.UserId
LEFT JOIN 
    CloseReasonDetails crd ON p.Id = crd.PostId
WHERE 
    p.Score > 10
ORDER BY 
    p.Score DESC, p.CreationDate DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

### Query Overview:
1. **RankedPosts CTE**: Ranks questions based on score for each user over the past year.
2. **UserBadges CTE**: Aggregates badges for each user, breaking down counts by badge class.
3. **CloseReasonDetails CTE**: Retrieves closure reasons for posts along with the post IDs.
4. **Main Query**: Combines the results into a detailed view of highly scored questions, including author details, badge counts, closure reasons, and ranking information, fetching a specific range of results for performance benchmarking.
