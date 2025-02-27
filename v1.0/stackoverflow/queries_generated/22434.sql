WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) -- Only Questions and Answers
),

PostScores AS (
    SELECT 
        PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        COUNT(v.Id) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS NetVotes
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '1 month' -- Votes in the last month
    GROUP BY 
        PostId
),

TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ps.UpVotes,
        ps.NetVotes,
        rp.OwnerDisplayName,
        COALESCE(rp.Rank, 0) AS UserRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostScores ps ON rp.PostId = ps.PostId
    WHERE 
        rp.Rank <= 5 -- Top 5 posts per user
)

SELECT 
    tp.PostId,
    tp.Title,
    CASE 
        WHEN tp.NetVotes > 0 THEN 'Positive'
        WHEN tp.NetVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteComment,
    tp.CreationDate,
    tp.OwnerDisplayName,
    COALESCE(b.Name, 'No Badge') AS UserBadge,
    COUNT(c.Id) AS CommentCount,
    (SELECT COUNT(1) 
     FROM PostHistory ph 
     WHERE ph.PostId = tp.PostId 
     AND ph.PostHistoryTypeId IN (10, 11) 
     AND ph.CreationDate BETWEEN tp.CreationDate AND NOW()) AS ClosureCount
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON tp.OwnerDisplayName = b.UserId 
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.OwnerDisplayName, tp.UpVotes, tp.NetVotes, b.Name
ORDER BY 
    tp.NetVotes DESC, tp.ViewCount DESC;

### Explanation:
1. **CTEs (Common Table Expressions)**: The query has multiple CTEs:
   - `RankedPosts`: Ranks posts based on score for each user.
   - `PostScores`: Calculates upvotes and net votes for each post in the last month.
   - `TopPosts`: Selects top 5 posts for each user and joins with scores.

2. **Window Functions**: The `ROW_NUMBER()` window function is used to assign rankings to posts.

3. **Correlated Subquery**: A correlated subquery counts how many times each post was closed in its time frame.

4. **String Expressions and CASE Logic**: The `CASE` statement evaluates net votes to decide the vote comment.

5. **NULL Logic**: Uses `COALESCE` to handle potential NULL values for badges and ranks.

6. **Outer Joins**: Left joins are used to include posts even when there are no associated votes, badges, or comments.

This complex query can serve as a benchmark for analyzing performance, as it includes diverse SQL constructs, filtering, aggregation, and conditional logic.
