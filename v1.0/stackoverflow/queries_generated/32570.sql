WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    
    UNION ALL
    
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.AcceptedAnswerId,
        cte.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE cte ON p.ParentId = cte.PostId
    WHERE 
        p.PostTypeId = 2  -- Only Answers
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.Level,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2), 0) AS UpvoteCount
    FROM 
        RecursivePostCTE rp
),
PopularPosts AS (
    SELECT 
        pd.*,
        ROW_NUMBER() OVER (PARTITION BY pd.Level ORDER BY pd.Score DESC, pd.CreationDate ASC) AS RowNum
    FROM 
        PostDetails pd
    WHERE 
        pd.Score > 10 -- Filter to only popular posts
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.Score,
    pp.CommentCount,
    pp.UpvoteCount,
    CASE 
        WHEN pp.Level = 1 THEN 'Question' 
        ELSE 'Answer' 
    END AS PostType,
    CASE 
        WHEN pp.UpvoteCount > 5 THEN 'Trending'
        ELSE 'Regular'
    END AS PopularityStatus
FROM 
    PopularPosts pp
WHERE 
    pp.RowNum <= 5 -- Grab top 5 posts per level
ORDER BY 
    pp.Level, 
    pp.Score DESC;

This SQL query performs the following operations:

1. **Recursive common table expression (CTE)**: The first CTE (`RecursivePostCTE`) retrieves all questions and their corresponding answers using recursive joins. Each level of answers is captured with the `Level` column.

2. **Post details gathering**: The second CTE (`PostDetails`) gathers additional details for each question and answer, including the total number of comments and the count of upvotes.

3. **Popular posts identification**: In `PopularPosts`, the query filters the posts based on their score and ranks them within their own levels using `ROW_NUMBER()` for further sorting.

4. **Final selection**: The outer query selects relevant fields, applies case logic to classify the post type and status, and limits the output to the top five posts for each level (question or answer).

This structure utilizes various SQL constructs including CTEs, window functions, and correlated subqueries, and applies logic with `CASE` to derive meaningful insights on the posts.
