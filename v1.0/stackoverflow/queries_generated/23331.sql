WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 month' 
        AND p.ViewCount IS NOT NULL
        AND p.Score IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(MAX(b.Class), 0) AS MaxBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
TopPostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    CROSS JOIN 
        LATERAL string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags)-2), '><') AS t(Tags) 
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate, 
        ph.UserId,
        COUNT(DISTINCT ph.Id) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId, ph.CreationDate, ph.UserId
)
SELECT 
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    ur.Reputation,
    ur.MaxBadgeClass,
    c.CloseCount,
    t.Tags
FROM 
    RankedPosts p
JOIN 
    UserReputation ur ON p.PostId = ur.UserId
LEFT JOIN 
    ClosedPosts c ON p.PostId = c.PostId
LEFT JOIN 
    TopPostTags t ON p.PostId = t.PostId
WHERE 
    p.rn = 1
    AND ur.Reputation > 1000
    AND (c.CloseCount IS NULL OR c.CloseCount < 2)
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100;

### Explanation of Constructs:
1. **Common Table Expressions (CTEs)**:
    - `RankedPosts`: Retrieves posts created in the last month grouped by the owner, ordered by `CreationDate`.
    - `UserReputation`: Calculates the maximum badge class for users.
    - `TopPostTags`: Extracts and aggregates post tags into a string for display.
    - `ClosedPosts`: Counts the number of times a post has been closed.

2. **Window Functions**:
    - `ROW_NUMBER()`: Used to retrieve the most recent post for each user.

3. **CROSS JOIN LATERAL**: 
    - Parses the tags from the `Tags` field using a lateral join.

4. **Conditional Logic**:
    - Uses `COALESCE` to handle potential NULL values for badge classes.
    
5. **Complex Predicates**:
    - Filters to ensure reputation is over 1000 and that posts are either never closed or have fewer than 2 close votes.

This query rests on complex aggregations, multiple join types, and advanced filtering that provide a benchmark for SQL performance in a realistic and nuanced context.
