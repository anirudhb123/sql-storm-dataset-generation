WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostBadges AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(c.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes c ON ph.Comment::int = c.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Only closed and reopened
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate AS PostCreationDate,
    COALESCE(pb.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(pb.Badges, 'No Badges') AS UserBadges,
    cp.CloseReasons,
    CASE 
        WHEN cp.CloseReasons IS NOT NULL THEN 
            CASE 
                WHEN rp.Score >= 10 THEN 'Highly Rated & Closed'
                ELSE 'Closed Post'
            END
        ELSE 
            CASE 
                WHEN rp.Score >= 10 THEN 'Popular Content'
                ELSE 'Standard Post'
            END
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostBadges pb ON pb.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC,
    rp.CreationDate DESC
OFFSET 10 ROWS 
FETCH NEXT 20 ROWS ONLY;

### Explanation:
1. **CTEs**: The query employs Common Table Expressions (CTEs) for organizing logic:
   - **RankedPosts**: Ranks posts within their type by creation date.
   - **PostBadges**: Aggregates badge counts and names for each user.
   - **ClosedPosts**: Collects close reason data for posts that were closed.

2. **LEFT JOINs**: Used to bring in badge counts and close reasons while ensuring that posts without these details remain in the result set.

3. **COALESCE**: Handles NULL values in badge data by providing default values.

4. **CASE statements**: Implements logic for categorizing posts based on their status—either closed or highly rated.

5. **Pagination**: The result set skips the first 10 entries and fetches the next 20 entries, useful for pagination or segmented data analysis.

6. **String Aggregation**: Used `STRING_AGG` for concatenating badge names and close reasons, providing concise summaries of these attributes.

7. **Correlated Subquery**: The query incorporates a correlated subquery to fetch the `OwnerUserId` needed for the badge aggregation.

This query is intended for performance benchmarking by demonstrating complexity with multiple SQL constructs, efficiently illustrating SQL's handling of aggregation, joins, window functions, and logical conditions.
