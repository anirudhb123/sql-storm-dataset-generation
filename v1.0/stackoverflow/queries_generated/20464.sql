WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PostDetails AS (
    SELECT 
        rp.PostId, 
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        CASE 
            WHEN rp.Score > 100 THEN 'Highly Engaged'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Moderately Engaged'
            ELSE 'Low Engagement'
        END AS EngagementLevel,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
ApprovedComments AS (
    SELECT 
        c.PostId,
        STRING_AGG(c.Text, '; ') AS Comments
    FROM 
        Comments c
    WHERE 
        c.Score > 0
    GROUP BY 
        c.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.CommentCount,
    pd.EngagementLevel,
    COALESCE(ac.Comments, 'No comments') AS AggregatedComments,
    CASE 
        WHEN pd.UpVoteCount > pd.DownVoteCount THEN 'More Positive Feedback'
        WHEN pd.UpVoteCount < pd.DownVoteCount THEN 'More Negative Feedback'
        ELSE 'Neutral Feedback'
    END AS FeedbackAnalysis,
    (SELECT 
        NULLIF(MAX(b.Class), 3) FROM Badges b WHERE b.UserId IN (
            SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = pd.PostId
        )
    ) AS HighestBadgeClass
FROM 
    PostDetails pd
LEFT JOIN 
    ApprovedComments ac ON pd.PostId = ac.PostId
ORDER BY 
    pd.ViewCount DESC NULLS LAST, 
    pd.Score DESC NULLS LAST;

### Explanation:
1. **Common Table Expressions (CTEs)**: 
   - **RankedPosts**: Ranks posts based on score and view count for the last year.
   - **PostDetails**: Enriches data with engagement levels, upvote/downvote counts, and more.
   - **ApprovedComments**: Aggregates positive comments for each post.

2. **Aggregations and Grouping**: Uses `STRING_AGG()` to combine comments and incorporates conditional logic for feedback analysis.

3. **NULL Logic**: Employs `COALESCE()` to handle posts without comments, and utilizes `NULLIF()` to conditionally find badge classes.

4. **Subqueries**: Nested subqueries for counts of votes and badge classes enhance the complexity.

5. **Outer Joins**: `LEFT JOIN` to include posts without comments.

6. **Sorting with NULLs Handling**: Orders results by view count and score, treating NULL values distinctly.

This complex query incorporates various SQL constructs and semantics for performance benchmarking, showcasing intricate data relationships typically found in a comprehensive database environment.
