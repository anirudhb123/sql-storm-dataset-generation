WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        rp.*,
        COALESCE(rp.CommentCount, 0) AS TotalComments,
        CASE 
            WHEN rp.Score > 100 THEN 'High Score' 
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium Score' 
            WHEN rp.Score < 50 THEN 'Low Score' 
            ELSE 'Unknown' 
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.ViewCount > 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.TotalComments,
    fp.ScoreCategory,
    CASE 
        WHEN fp.TotalComments IS NULL THEN 'No Comments'
        ELSE CONCAT(fp.TotalComments, ' Comment(s)')
    END AS CommentInfo,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    FilteredPosts fp
LEFT JOIN 
    LATERAL (
        SELECT 
            t.TagName 
        FROM 
            UNNEST(string_to_array(fp.Tags, ',')) AS t(TagName) 
        WHERE 
            t.TagName IS NOT NULL
    ) AS t ON TRUE
LEFT JOIN 
    PostLinks pl ON fp.PostId = pl.PostId
LEFT JOIN 
    Posts related ON pl.RelatedPostId = related.Id
GROUP BY 
    fp.PostId, fp.Title, fp.CreationDate, fp.ViewCount, fp.Score, fp.TotalComments, fp.ScoreCategory
ORDER BY 
    fp.CreationDate DESC
LIMIT 25
OPTION (MAXDOP = 4);

### Explanation:
1. **CTE Ranking Posts**: The first CTE (`RankedPosts`) ranks posts by creation date within their type, counts comments, and aggregates upvotes and downvotes.

2. **Filtered Posts**: The second CTE (`FilteredPosts`) filters these posts further by their view count and classifies them based on their score into 'High', 'Medium', and 'Low' categories.

3. **Main Query**: 
   - It retrieves data from `FilteredPosts` and joins with a lateral subquery to extract distinct tags, also handling NULL counts with COALESCE.
   - It creates a string representation of the comment details and compiles all necessary information to return in the result set.

4. **Advanced Constructs**: It utilizes window functions, string manipulation, conditional logic, and aggregate functions, reflecting comprehensive SQL capabilities while managing nuanced semantics and NULL values. 

5. **Performance Options**: `LIMIT` is used to cap results and `OPTION` hints (if supported) might be considered for parallel processing to enhance performance.

This query exemplifies various SQL features, intricate logic, and potential corner cases that could arise in a production environment.
