WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > DATEADD(YEAR, -1, GETDATE())
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
    GROUP BY 
        ph.PostId
),

UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBountyAmount,
        COUNT(v.Id) AS TotalVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    coalesce(cp.CloseCount, 0) AS NumberOfClosures,
    cp.CloseReasons,
    us.UserId,
    us.DisplayName,
    us.TotalBountyAmount,
    us.TotalVotes,
    us.BadgeCount
FROM 
    RankedPosts rp
LEFT OUTER JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
JOIN 
    UserStatistics us ON us.UserId = rp.OwnerUserId
WHERE 
    rp.ViewRank <= 5 
    AND rp.PostTypeId = 1  -- Questions only
    AND COALESCE(cp.CloseCount, 0) < 2  -- Not closed more than once
ORDER BY 
    rp.ViewCount DESC, 
    us.TotalVotes DESC;

### Explanation of SQL Constructs:

1. **Common Table Expressions (CTEs):**
   - **RankedPosts:** Ranks posts created in the last year by view count per post type.
   - **ClosedPosts:** Counts closures and aggregates close reasons for each post.
   - **UserStatistics:** Aggregates user data, including total bounties and badges for users with a reputation greater than 1000.

2. **Window Functions:**
   - `ROW_NUMBER()` is used to rank posts within different post types based on their view count.

3. **Outer Joins:**
   - LEFT OUTER JOIN is applied to fetch closure details even if there are no closures.

4. **String Aggregation:**
   - `STRING_AGG` is used to concatenate distinct close reasons for each post, accommodating NULL logic for closed posts.

5. **Complicated Predicates:**
   - The final selection filters to include only the top-viewed questions that have not been closed more than once.

6. **NULL Logic:**
   - The use of COALESCE to handle NULL values from joins ensures accurate counts and outputs.

7. **Bizarre Semantics:**
   - The query makes assumptions about the way different post types might interact with closures (e.g., excluding frequently-closed questions). 

This complex query serves a purpose of performance benchmarking, providing insights into post engagement, closure metrics, and user reputations, all while demonstrating advanced SQL constructs.
