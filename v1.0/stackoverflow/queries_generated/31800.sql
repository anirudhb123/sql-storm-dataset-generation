WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) AS TotalScore,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END), 0) DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
),
PostHistoryAnalysis AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 1 THEN ph.CreationDate END) AS InitialTitleDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 2 THEN ph.CreationDate END) AS InitialBodyDate,
        COUNT(DISTINCT ph.UserId) AS EditorCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
CombinedStats AS (
    SELECT 
        ps.PostId,
        u.DisplayName AS PostOwner,
        ps.TotalScore,
        ps.CommentCount,
        ps.RelatedPostCount,
        ph.InitialTitleDate,
        ph.InitialBodyDate,
        ph.EditorCount
    FROM 
        RecursivePostStats ps
    INNER JOIN 
        Users u ON ps.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistoryAnalysis ph ON ps.PostId = ph.PostId
)
SELECT 
    cs.PostId,
    cs.PostOwner,
    cs.TotalScore,
    cs.CommentCount,
    cs.RelatedPostCount,
    COALESCE(cs.InitialTitleDate, 'Never') AS FirstTitleChange,
    COALESCE(cs.InitialBodyDate, 'Never') AS FirstBodyChange,
    cs.EditorCount
FROM 
    CombinedStats cs
WHERE 
    cs.TotalScore > 0
ORDER BY 
    cs.TotalScore DESC, cs.CommentCount DESC
LIMIT 50;

This SQL query leverages a series of Common Table Expressions (CTEs) to evaluate various dimensions of post interactions within the Stack Overflow schema:

1. **RecursivePostStats**: This CTE calculates total scores from votes, counts comments per post, and counts the number of related posts linked to a given post.
   
2. **PostHistoryAnalysis**: This CTE analyzes how often posts have been edited, specifically noting their initial titles and bodies and how many different users have made edits.

3. **CombinedStats**: Combines information from both previous CTEs, providing a comprehensive view that includes the post owner's display name, total score, comment count, and the count of initial edits made.

The final result set includes fields relevant for performance benchmarking, sorting high-scoring posts and including display names, initial change dates for titles and bodies, showcasing a diverse range of SQL constructs such as CTEs, window functions, aggregate functions, and conditional logic.
