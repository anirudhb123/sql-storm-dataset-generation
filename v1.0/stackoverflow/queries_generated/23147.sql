WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerUserId,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.Rank <= 10 THEN 'Top 10'
            ELSE 'Others'
        END AS PostRankCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 50
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.OwnerUserId,
    tp.UpVotes,
    tp.DownVotes,
    COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
    (SELECT COUNT(*) 
     FROM Comments c 
     WHERE c.PostId = tp.PostId) AS CommentCount,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     JOIN UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag ON t.TagName = tag
     WHERE p.Id = tp.PostId) AS RelatedTags,
    CASE 
        WHEN tp.Score <= 0 THEN 'Needs Attention'
        WHEN tp.UpVotes IS NULL OR tp.DownVotes IS NULL THEN 'Vote Data Missing'
        ELSE 'Active Post'
    END AS PostHealth
FROM 
    TopPosts tp
LEFT JOIN 
    Users u ON tp.OwnerUserId = u.Id
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC;


### Description of SQL Query Components:
1. **Common Table Expressions (CTEs)**: 
   - `RankedPosts` ranks posts based on their type and score within the last year.
   - `TopPosts` filters these posts to return the top-ranked posts.

2. **Window Functions**: 
   - The `ROW_NUMBER()` function assigns ranks to posts based on their score in their respective types.

3. **Correlated Subqueries**:
   - Counting comments associated with each post directly within the main query.
   - Extracting related tags from a string array.

4. **String Expressions**:
   - `STRING_AGG` is used for concatenating related tag names from the `Tags` table.

5. **NULL Logic**: 
   - `COALESCE` to handle potentially deleted users.

6. **Complex Case Statements**: 
   - Categorizes posts into 'Top 10', 'Others', or assesses health based on score and vote data.

7. **Aggregated Filters**:
   - Use of the `FILTER` clause within `COUNT` to classify upvotes and downvotes.

8. **Ordering**:
   - Final results sorted by score and creation date, presenting the highest scored posts first.

This query showcases various sophisticated SQL techniques while ensuring robust performance for benchmarking purposes.
