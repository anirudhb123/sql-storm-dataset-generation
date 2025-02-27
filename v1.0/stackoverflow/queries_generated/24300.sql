WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY STRING_AGG(t.TagName, ', ') OVER (ORDER BY t.TagName) ORDER BY p.Score DESC) AS TagRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        p.AcceptedAnswerId
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL (SELECT * FROM STRING_TO_ARRAY(p.Tags, ',') AS tag) AS t ON TRUE
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 AND  -- Only questions
        p.Score > 0           -- Only questions with a positive score
),
CommentedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.Tags,
        rp.TagRank,
        COALESCE(SUM(CASE WHEN c.Score IS NULL THEN 0 ELSE c.Score END), 0) AS TotalCommentScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.Tags, rp.TagRank
),
FinalPosts AS (
    SELECT 
        cp.PostId,
        cp.Title,
        cp.Score,
        cp.Tags,
        cp.TagRank,
        cp.TotalCommentScore,
        CASE 
            WHEN cp.TotalCommentScore > 0 THEN 'Commented'
            ELSE 'Uncommented'
        END AS CommentStatus,
        CASE 
            WHEN EXISTS (SELECT 1 FROM Posts AS a WHERE a.Id = cp.PostId AND a.AcceptedAnswerId IS NOT NULL) 
            THEN 'Accepted Answer Available'
            ELSE 'No Accepted Answer'
        END AS AnswerStatus
    FROM 
        CommentedPosts cp
)
SELECT 
    f.PostId,
    f.Title,
    f.Score,
    f.Tags,
    f.TagRank,
    f.TotalCommentScore,
    f.CommentStatus,
    f.AnswerStatus,
    COUNT(DISTINCT v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
FROM 
    FinalPosts f
LEFT JOIN 
    Votes v ON f.PostId = v.PostId
GROUP BY 
    f.PostId, f.Title, f.Score, f.Tags, f.TagRank, f.TotalCommentScore, f.CommentStatus, f.AnswerStatus
ORDER BY 
    f.TotalCommentScore DESC, f.Score DESC
LIMIT 100;

This SQL query uses Common Table Expressions (CTEs) to create a layered approach for analyzing questions based on their scores, comment counts, and associated tags. It incorporates conditional logic, ranking, and aggregation, along with performance-friendly constructs such as window functions, lateral joins, and correlated subqueries. Additionally, it gives a rich overview of vote counts and categorizes posts based on their engagement status, making it a robust solution for performance benchmarking in an SQL environment.
