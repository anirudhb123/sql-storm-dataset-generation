WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS PostCount,
        SUM(COALESCE(com.Score, 0)) OVER (PARTITION BY p.OwnerUserId) AS TotalCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments com ON p.Id = com.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate AS CloseDate,
        cr.Name AS CloseReason
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Close or Reopen actions
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END), 0) AS PositivePostScores
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.BadgeCount,
    us.TotalBounties,
    us.PositivePostScores,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.Score AS RecentPostScore,
    cl.CloseDate,
    cl.CloseReason,
    rp.PostCount,
    rp.TotalCommentScore
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.rn = 1 -- Get most recent post
LEFT JOIN 
    ClosedPosts cl ON cl.PostId = rp.PostId
WHERE 
    us.Reputation > 0
ORDER BY 
    us.Reputation DESC, 
    us.BadgeCount DESC, 
    rp.Score DESC
LIMIT 100;
This query retrieves user statistics including the most recent post for users with a positive reputation, their badge counts, the total bounty amount they have received, and any closed post details. The query makes use of Common Table Expressions (CTEs) to rank posts, gather close reasons, and summarize user statistics, all while utilizing complex predicates and aggregate functions to handle various cases in the dataset.
