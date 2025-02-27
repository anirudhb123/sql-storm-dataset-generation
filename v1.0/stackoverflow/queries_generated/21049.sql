WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Fetch BountyStart and BountyClose
    WHERE 
        p.CreationDate >= '2020-01-01' -- Only consider posts created from January 2020 onwards
    GROUP BY 
        p.Id, pt.Name, p.Title, p.CreationDate
),
UserBountyStatus AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 8 THEN v.BountyAmount ELSE 0 END) AS TotalBountySpent,
        COUNT(CASE WHEN v.VoteTypeId = 9 THEN 1 END) AS BountyClosedCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9)
    GROUP BY 
        u.Id
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        RANK() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RecentChangeRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) -- Closed, Reopened, Deleted actions
),
CombinedStatus AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.TotalBounty,
        ub.TotalBountySpent,
        ub.BountyClosedCount,
        rph.Comment AS RecentActionComment,
        rph.CreationDate AS RecentActionDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBountyStatus ub ON ub.UserId = (
            SELECT 
                OwnerUserId 
            FROM 
                Posts 
            WHERE 
                Id = rp.PostId
        )
    LEFT JOIN 
        RecentPostHistory rph ON rp.PostId = rph.PostId AND rph.RecentChangeRank = 1
)
SELECT 
    cs.PostId,
    cs.Title,
    cs.CreationDate,
    cs.CommentCount,
    cs.TotalBounty,
    COALESCE(cs.RecentActionComment, 'No recent action') AS RecentActionComment,
    COALESCE(cs.RecentActionDate::date, 'N/A') AS RecentActionDate,
    CASE 
        WHEN cs.TotalBounty > 0 AND cs.BountyClosedCount > 0 THEN 'Active Bounty'
        WHEN cs.TotalBounty = 0 THEN 'No Bounty'
        ELSE 'Bounty Inactive'
    END AS BountyStatus
FROM 
    CombinedStatus cs
WHERE 
    cs.CommentCount > 0 OR cs.TotalBounty > 0
ORDER BY 
    cs.TotalBounty DESC, cs.CommentCount DESC;
