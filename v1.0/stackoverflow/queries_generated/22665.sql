WITH UserPosts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        DENSE_RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS ClosedCount,
        AVG(COALESCE(v.BountyAmount, 0)) AS AverageBounty
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) -- Close and Reopen actions
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (9, 10) -- BountyClose and Deletion
    GROUP BY 
        p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class = 1 -- Gold badges only
    GROUP BY 
        u.Id
),
PostLinkCounts AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
),
Combined AS (
    SELECT 
        up.UserId,
        up.PostCount,
        up.TotalScore,
        cp.ClosedCount,
        cp.AverageBounty,
        ub.BadgeNames,
        COALESCE(pl.RelatedPostCount, 0) AS RelatedPostCount
    FROM 
        UserPosts up
    LEFT JOIN 
        ClosedPosts cp ON up.UserId = cp.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON up.UserId = ub.UserId
    LEFT JOIN 
        PostLinkCounts pl ON up.UserId = pl.PostId
)
SELECT 
    UserId,
    PostCount,
    TotalScore,
    ClosedCount,
    AverageBounty,
    BadgeNames,
    RelatedPostCount
FROM 
    Combined
WHERE 
    UserRank <= 10 -- Top 10 users by post count
    AND (ClosedCount IS NULL OR ClosedCount > 5) -- Filter for users with closed posts or none at all
ORDER BY 
    TotalScore DESC, PostCount DESC;
