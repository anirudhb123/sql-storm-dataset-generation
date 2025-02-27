WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as Rank,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= DATEADD(YEAR, -2, GETDATE()) -- Last 2 years
),
AggregatedVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserBadges AS (
    SELECT 
        ub.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    JOIN 
        Users ub ON b.UserId = ub.Id
    GROUP BY 
        ub.UserId
),
ClosedPosts AS (
    SELECT DISTINCT
        ph.PostId
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed and Reopened
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    av.UpVotes,
    av.DownVotes,
    av.TotalVotes,
    ub.BadgeCount AS UserBadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    CASE 
        WHEN pp.AcceptedAnswerId IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS AcceptedAnswer,
    CASE 
        WHEN cp.PostId IS NOT NULL THEN 'Closed' 
        ELSE 'Active' 
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    AggregatedVotes av ON rp.PostId = av.PostId
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank = 1 -- Get the most recent question per user
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;

### Explanation:

1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: Fetches questions with a rank based on creation date per user.
   - `AggregatedVotes`: Aggregates votes for each post to count upvotes and downvotes.
   - `UserBadges`: Counts total badges per user and segregates them by type (Gold, Silver, Bronze).
   - `ClosedPosts`: Identifies unique posts that have been closed or reopened.

2. **JOIN Operations**:
   - Various `LEFT JOIN`s connect posts to votes, users, user badges, and closed posts, demonstrating complex relation handling.

3. **CASE Statements & COALESCE**: 
   - Used for determining the presence of accepted answers and post status.

4. **Filtering & Ordering**:
   - Filters questions from the past two years and sorts the final result by score and view count.

5. **Performance Benchmarking**:
   - Demonstrates the use of analytical functions with window functions, aggregation, and conditional logic, which can be heavy on computation, in a single holistic query useful for performance testing.
