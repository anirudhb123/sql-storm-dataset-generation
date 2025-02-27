WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)
    GROUP BY 
        u.Id, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MAX(ph.CreationDate) AS LatestCloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Close and Reopen actions
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.Score,
    rp.ViewCount,
    us.Reputation,
    us.PostCount,
    us.TotalBounties,
    COALESCE(cp.LatestCloseDate, 'Not Closed') AS LatestCloseDate,
    CASE 
        WHEN rp.RankByScore <= 5 THEN 'Top Post'
        WHEN rp.RankByScore BETWEEN 6 AND 15 THEN 'Trending'
        ELSE 'Other'
    END AS PostCategory
FROM 
    RankedPosts rp
JOIN 
    UserStatistics us ON rp.OwnerUserId = us.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    us.PostCount > 5 -- Users who have posted more than 5 times
    AND us.TotalBounties IS NULL -- Users who haven't received bounties
    AND (rp.ViewCount >= 100 OR rp.Score >= 10) -- Posts should either have high views or score
ORDER BY 
    rp.Score DESC, 
    rp.PostCreationDate DESC;

-- In the subquery: For confusing NULL logic, we use COALESCE to represent non-closed posts 
-- and creatively categorize posts based on their rank and conditions specified.
