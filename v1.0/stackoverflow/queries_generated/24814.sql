WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.ViewCount > 0
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        u.Reputation,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    ub.UserId,
    ub.BadgeCount,
    ub.Reputation,
    ub.ReputationCategory,
    COALESCE(rp.UpVoteCount - rp.DownVoteCount, 0) AS NetVoteCount,
    CASE 
        WHEN rp.Rank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostRanking,
    'https://example.com/' || rp.Title AS PostLink,
    CONCAT('Created on ', TO_CHAR(rp.CreationDate, 'FMMonth FMDD, YYYY')) AS CreationInfo
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.PostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = ub.UserId
    )
WHERE 
    rp.Rank <= 10 
    AND ub.BadgeCount IS NOT NULL
ORDER BY 
    rp.Score DESC, ub.Reputation DESC
FETCH FIRST 50 ROWS ONLY;

### Breakdown of the Query:

1. **Common Table Expressions (CTEs):**
    - `RankedPosts`: Gathers posts that were created in the last year, counting upvotes and downvotes and ranking them within their post type.
    - `UserBadges`: Calculates the number of badges each user has earned, categorizing users based on their reputation.

2. **Row Numbers and Window Functions:**
    - Uses `ROW_NUMBER()` to rank posts by score and creation date while partitioning by `PostTypeId`.

3. **Correlated Subqueries:**
    - Counts the number of upvotes and downvotes for each post within the `RankedPosts`.

4. **Complex Predicate Logic:**
    - Filtering based on view counts and the age of posts, ensuring only relevant and active posts are included.

5. **String Expressions:**
    - Generates links and reformats creation dates into a human-readable format.

6. **Outer Joins:**
    - Left join to incorporate user badge counts, ensuring posts are returned even if a user does not have any badges.

7. **NULL Logic:**
    - Use of `COALESCE` to handle situations where upvotes might be null, providing a net vote count.

8. **Ordering and Row Limiting:**
    - Orders by post score and user reputation, returning a limited number of records for performance benchmarking.
