WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) 
        AND p.ViewCount IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        SUM(b.Class) AS TotalBadgeClass,
        u.Reputation,
        u.CreationDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.CreationDate
),
UserScore AS (
    SELECT 
        up.UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 
                 WHEN v.VoteTypeId = 3 THEN -1 
                 ELSE 0 END) AS NetVotes
    FROM 
        Users up
    LEFT JOIN 
        Votes v ON up.Id = v.UserId
    GROUP BY 
        up.UserId
)
SELECT 
    p.Title,
    p.ViewCount,
    u.Reputation,
    u.TotalBadgeClass,
    us.NetVotes,
    CASE 
        WHEN p.ViewCount IS NULL THEN 'No Views Recorded' 
        WHEN p.Score > 10 THEN 'Highly Rated Post' 
        ELSE 'Average Post' 
    END AS PostQuality,
    COALESCE(NULLIF(p.CreationDate, '')::date, DATE '1900-01-01') AS CreationDate
FROM 
    RankedPosts p
JOIN 
    UserReputation u ON p.OwnerUserId = u.UserId
LEFT OUTER JOIN 
    UserScore us ON p.OwnerUserId = us.UserId
WHERE 
    p.Rank <= 5
    AND (u.Reputation > 100 OR (p.ViewCount > 50 AND us.NetVotes > 0))
ORDER BY 
    p.ViewCount DESC, u.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;


This SQL query accomplishes several tasks:

1. It creates three Common Table Expressions (CTEs):
   - `RankedPosts` ranks posts by type and score while counting comments.
   - `UserReputation` aggregates user badge classes to calculate a total score for each user.
   - `UserScore` calculates the net votes received by each user.

2. The main query selects various columns while applying complex filtering and ranking.
3. It introduces CASE statements to classify posts and COALESCE with NULLIF to handle corner cases around the `CreationDate` field.
4. The final result is sorted and paginated to fetch the top results.

Thus, the design includes outer joins, CTEs, ranking, conditional logic, and handles scenarios where certain fields may be NULL or require custom logic.
