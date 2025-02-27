WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
        AND p.Score IS NOT NULL
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Rank,
        CASE 
            WHEN rp.Rank <= 10 THEN 'Top 10 Posts'
            ELSE 'Other Posts'
        END AS Category
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 20
),

CloseReasonCount AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseReasonCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CreationDate,
    tp.ViewCount,
    tp.AnswerCount,
    tp.Category,
    COALESCE(crc.CloseReasonCount, 0) AS CloseReasonCount,
    CASE 
        WHEN crc.IsClosed = 1 THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation
FROM 
    TopPosts tp
LEFT JOIN 
    CloseReasonCount crc ON tp.PostId = crc.PostId
LEFT JOIN 
    Users U ON U.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
WHERE 
    tp.QuestionCount > 0
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC
LIMIT 50;

-- Optional: To explore edge cases, consider checking for NULLs in OwnerDisplayName and showing a default value:
SELECT 
    COALESCE(U.DisplayName, 'Anonymous') AS OwnerDisplayName,
    ...
FROM 
    TopPosts tp
LEFT JOIN 
    ...

### Explanation:
1. **CTEs (`WITH` clauses)**:
   - **RankedPosts**: This CTE ranks posts by score and counts associated comments while filtering for posts created in the last year.
   - **TopPosts**: This filters to get the top 20 ranked posts, categorizing them into top 10 and others.
   - **CloseReasonCount**: This counts the number of close reason events for each post and identifies if a post is closed.

2. **Main Query**: 
   - Selects data from the `TopPosts`, correlating with close reasons and the associated user information.
   - Category and status of posts are determined using conditional logic.
   - The final output is ordered by score and creation date, limiting results to 50.

3. **Handling Edge Cases**: 
   - The optional segment at the end includes logic to handle potential NULL values, ensuring that user display names are meaningful.
