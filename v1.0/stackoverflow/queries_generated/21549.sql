WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
        AND p.ViewCount IS NOT NULL
), 
UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT v.PostId) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
), 
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Only close history
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    us.TotalUpVotes,
    us.TotalDownVotes,
    cr.CloseReasonNames,
    CASE 
        WHEN rp.RankByViews <= 5 THEN 'Top Viewed'
        WHEN rp.RankByScore <= 5 THEN 'Top Scored'
        ELSE 'Others'
    END AS ViewScoreCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVoteStats us ON rp.PostId = us.UserId
LEFT JOIN 
    CloseReasons cr ON rp.PostId = cr.PostId
WHERE 
    (cr.CloseReasonNames IS NOT NULL OR us.TotalVotes > 0)
    AND rp.RankByViews < 10
ORDER BY 
    rp.ViewCount DESC NULLS LAST,
    rp.Score DESC NULLS LAST;

This SQL query does the following:

1. **Rank the Posts**: A Common Table Expression (CTE) `RankedPosts` derives ranking based on view counts and scores for posts created in the last year.
2. **Aggregate User Votes**: The CTE `UserVoteStats` summarizes the total upvotes and downvotes for each user and counts distinct post votes.
3. **Gather Close Reasons**: Another CTE `CloseReasons` collects the close reasons for each post from the `PostHistory` table.
4. **Final Selection**: The main query selects from these CTEs and joins user voting statistics and close reasons, applying complex predicates to filter results based on these statistics.
5. **Categorization**: A conditional expression categorizes posts into 'Top Viewed' or 'Top Scored', or 'Others' based on their ranks.

Overall, this query incorporates various SQL features such as CTEs, window functions, CASE statements, and outer joins and deals with NULLs logically while aggregating and filtering complex datasets.
