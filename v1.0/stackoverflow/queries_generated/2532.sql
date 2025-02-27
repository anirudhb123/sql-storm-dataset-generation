WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1) 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment
    FROM 
        PostHistory ph
    INNER JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        pht.Name = 'Post Closed'
),
FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        us.Reputation,
        cp.Comment AS CloseComment,
        ROW_NUMBER() OVER (ORDER BY rp.ViewCount DESC) AS PopularityRank
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.PostId
    WHERE 
        rp.rn = 1
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Reputation,
    COALESCE(fp.CloseComment, 'Not Closed') AS PostStatus,
    CASE 
        WHEN fp.ViewCount > 1000 THEN 'Popular'
        WHEN fp.ViewCount > 500 THEN 'Average'
        ELSE 'Less Popular'
    END AS PopularityCategory
FROM 
    FilteredPosts fp
WHERE 
    fp.PopularityRank <= 10
ORDER BY 
    fp.ViewCount DESC;
