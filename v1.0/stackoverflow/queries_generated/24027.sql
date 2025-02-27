WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 
                 WHEN v.VoteTypeId = 3 THEN -1 
                 ELSE 0 END) AS NetScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        u.CreationDate,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.LastAccessDate >= NOW() - INTERVAL '6 months'
),
RelatedPosts AS (
    SELECT 
        pl.PostId,
        COALESCE((SELECT STRING_AGG(p.Title, ', ')
                   FROM Posts p
                   JOIN PostLinks pl2 ON pl2.RelatedPostId = p.Id
                   WHERE pl2.PostId = pl.PostId), 'No Related Posts') AS RelatedPostTitles
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.OwnerName,
    r.CommentCount,
    r.NetScore,
    a.ReputationRank,
    a.DisplayName AS ActiveUserName,
    rp.RelatedPostTitles
FROM 
    RankedPosts r
JOIN 
    ActiveUsers a ON r.OwnerPostRank <= 3
LEFT JOIN 
    RelatedPosts rp ON r.PostId = rp.PostId
WHERE 
    r.CommentCount > 5 
    AND r.NetScore IS NOT NULL 
    AND a.UserId IS NOT NULL
ORDER BY 
    r.NetScore DESC, r.CommentCount DESC
LIMIT 20;

### Explanation:
1. **CTEs (Common Table Expressions)**:
   - **RankedPosts**: Gathers post information with net score calculation for questions posted in the last year, counting their comments while ranking by creation date per user.
   - **ActiveUsers**: Identifies users active within the last six months, ranking them by reputation.
   - **RelatedPosts**: Retrieves titles of related posts linked through `PostLinks`. If none are found, it defaults to a placeholder.

2. **Main SELECT**: Combines post data with active user and related post information, filtering for posts with significant interaction.

3. **JOINs**: 
   - An inner join merges `RankedPosts` and `ActiveUsers`, ensuring only posts by highly ranked active users are considered.
   - A left join brings in related posts while maintaining the core set of active posts.

4. **WHERE Clause Conditions**: Ensures that results meet specific criteria for comments and net score—highlighting interaction.

5. **Ordering and Limiting**: Results are sorted by net score and comment count, showing dynamic and engaging posts first, limited to the top 20 to maintain focus.

This query illustrates sophisticated SQL techniques like CTEs, window functions, conditional aggregations, and logic handling for related dataset extraction, showcasing a blend of complexity and utility for performance benchmarks.
