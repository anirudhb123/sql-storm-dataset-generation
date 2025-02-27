WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year') 
        AND p.Score IS NOT NULL
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT pc.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.CreationDate >= (CURRENT_DATE - INTERVAL '6 months') 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    LEFT JOIN 
        Posts pc ON u.Id = pc.OwnerUserId AND pc.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        p.Title AS ClosedTitle,
        p.OwnerUserId,
        ph.CreationDate AS CloseDate,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        ph.PostHistoryTypeId = 10
),
AggregateStats AS (
    SELECT 
        us.UserId,
        COALESCE(SUM(rp.Score), 0) AS TotalScore,
        COALESCE(MAX(CASE WHEN rp.RN = 1 THEN rp.Score END), 0) AS MaxPostScore,
        COUNT(DISTINCT cp.ClosedPostId) AS ClosedPostCount
    FROM 
        UserStats us
    LEFT JOIN 
        RankedPosts rp ON us.UserId = rp.PostId
    LEFT JOIN 
        ClosedPosts cp ON us.UserId = cp.OwnerUserId
    GROUP BY 
        us.UserId
)
SELECT 
    us.DisplayName,
    us.TotalBounties,
    us.BadgeCount,
    as.TotalScore,
    as.MaxPostScore,
    as.ClosedPostCount
FROM 
    UserStats us
JOIN 
    AggregateStats as ON us.UserId = as.UserId
WHERE 
    us.BadgeCount >= 5 
    OR as.TotalScore > 100
ORDER BY 
    as.TotalScore DESC, 
    us.BadgeCount DESC;

This query performs several complex tasks:

1. **RankedPosts** CTE ranks posts per user based on scores and recency.
2. **UserStats** CTE collects statistics for users, including total bounties, badge counts, and the number of posts they've authored.
3. **ClosedPosts** CTE identifies posts that have been closed with their details.
4. **AggregateStats** combines the ranks, scores, and counts to provide an overall picture for each user.
5. The final selection filters users by badge count or total score, displaying the relevant metrics, while organizing results for easier analysis.
