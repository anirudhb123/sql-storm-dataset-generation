WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS GlobalRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
PostDetails AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        COALESCE(ph.PostHistoryTypeId, 0) AS LastHistoryType,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId = 2) AS Upvotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId = 3) AS Downvotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.Id = ph.PostId AND ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = rp.Id)
)
SELECT 
    pd.Id,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.Score,
    pd.Upvotes,
    pd.Downvotes,
    CASE 
        WHEN pd.LastHistoryType IN (10, 11) THEN 'Closed or Reopened'
        WHEN pd.ViewCount > 1000 THEN 'Popular Post'
        ELSE 'Regular Post'
    END AS PostCategory,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     JOIN Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
     WHERE p.Id = pd.Id) AS Tags
FROM 
    PostDetails pd
WHERE 
    pd.PostRank <= 5
ORDER BY 
    pd.GlobalRank, pd.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- Optional part to simulate a bizarre semantic case with NULL logic
SELECT 
    *
FROM 
    Users u
WHERE 
    u.Id IN (
        SELECT DISTINCT pd.Id
        FROM PostDetails pd
        WHERE pd.OwnerDisplayName IS NULL OR pd.OwnerDisplayName = ''
    ) 
    OR u.Reputation IS NULL OR u.Reputation < 0
    AND NOT EXISTS (
        SELECT 1
        FROM Posts p
        WHERE p.OwnerUserId = u.Id 
        AND p.Score < 0
    )
ORDER BY 
    COALESCE(u.Reputation, 0) DESC;
This query includes the following SQL constructs and features:
- Common Table Expressions (CTEs) to organize data into ranked posts and details.
- Window functions for row ranking and dense ranking.
- Correlated subqueries for calculating upvotes and downvotes.
- Conditional logic with CASE statements.
- STRING_AGG used to concatenate tags from the related posts.
- Used complex NULL logic to handle semantical corner cases in the final selection of users.
- Retrieving paginated results and exploring post relevance with various predicates.
