WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(p.AcceptedAnswerId, -1) AS AnswerId -- Using COALESCE to manage NULLs
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score > (SELECT AVG(Score) FROM Posts WHERE CreationDate >= NOW() - INTERVAL '1 year')
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseVoteCount,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Close votes
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    us.TotalPosts,
    us.TotalBadges,
    us.TotalBounty,
    cp.CloseVoteCount,
    cp.LastClosedDate
FROM 
    RankedPosts rp
JOIN 
    UserStats us ON rp.AnswerId = us.UserId -- This joins based on the accepted answer's owner
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    us.TotalPosts > 5
    AND (cp.CloseVoteCount IS NULL OR cp.LastClosedDate < NOW() - INTERVAL '3 months')
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;

This SQL query encompasses quite a few advanced SQL concepts: 

1. **Common Table Expressions (CTEs)**: Used for structured queries to organize code and build up complex logic.
2. **Window Functions**: `ROW_NUMBER()` is used to rank posts by creation date within the types of posts.
3. **Correlated Subqueries**: The subquery calculating the average score in the `WHERE` clause.
4. **Outer Joins**: LEFT joins to pull in optional records from related tables (Badges, Votes).
5. **NULL Handling**: Using `COALESCE()` to handle potential NULLs in calculations.
6. **Aggregate Functions**: Such as `COUNT()` and `SUM()`.
7. **Filtering with Subquery**: A filtering condition in `WHERE` clause ensures only users with more than 5 posts are considered.
8. **Ordering and Limits**: To cap the records returned to manageable numbers and meaningful ordering. 

This query is designed not only to benchmark performance with its complexity but also to give insights into user participation alongside post popularity metrics.
