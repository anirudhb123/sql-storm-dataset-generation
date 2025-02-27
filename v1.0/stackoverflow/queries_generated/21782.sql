WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(COUNT(c.Id) FILTER (WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVotes,
        p.CreationDate,
        EXTRACT(YEAR FROM p.CreationDate) AS CreationYear
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '5 years'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate
),
PopularQuestions AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.NetVotes,
        rp.CreationYear,
        CASE 
            WHEN rp.Score >= 100 THEN 'Hot'
            WHEN rp.Score >= 50 THEN 'Warm'
            ELSE 'Cold'
        END AS Temperature
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS ReasonNames
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
)
SELECT 
    pq.Title,
    pq.ViewCount,
    pq.Score,
    pq.CommentCount,
    pq.NetVotes,
    pq.Temperature,
    cr.ReasonNames
FROM 
    PopularQuestions pq
LEFT JOIN 
    CloseReasons cr ON pq.Id = cr.PostId
ORDER BY 
    pq.ViewCount DESC NULLS LAST,
    pq.Score DESC
LIMIT 100;

### Explanation:
1. **CTE `RankedPosts`**: Calculates a rank for posts by their score, counting comments and net votes using conditional aggregation within a **window function**.
2. **CTE `PopularQuestions`**: Filters the top-ranked questions (by score) and categorizes them into "Hot", "Warm", or "Cold" based on their score.
3. **CTE `CloseReasons`**: Aggregates close reasons for posts that have been closed using `STRING_AGG`.
4. The final query selects relevant columns from the `PopularQuestions` CTE, joins with the `CloseReasons` for additional context, and sorts by view count with NULLs last, ensuring that non-closed questions come first.

This complex query establishes a rich selection of data to effectively benchmark SQL performance while incorporating various constructs such as joins, aggregations, case statements, and window functions.
