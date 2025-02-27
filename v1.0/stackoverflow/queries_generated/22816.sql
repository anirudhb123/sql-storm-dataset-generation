WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.Score > 100 THEN 'High Score'
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = rp.PostId) AS UserBadgeCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.ScoreCategory,
    COALESCE(fp.UserBadgeCount, 0) AS BadgeCount,
    (SELECT STRING_AGG(pt.Name, ', ') 
     FROM PostHistory ph 
     JOIN PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id 
     WHERE ph.PostId = fp.PostId) AS PostHistoryTypes,
    (SELECT COUNT(*) 
     FROM PostLinks pl 
     WHERE pl.PostId = fp.PostId 
       AND pl.LinkTypeId = 1) AS LinkedPostsCount,
    (SELECT MIN(p.Score) 
     FROM Posts p 
     WHERE p.OwnerUserId = (
         SELECT OwnerUserId 
         FROM Posts 
         WHERE Id = fp.PostId
     ) 
     AND p.Id != fp.PostId) AS MinScoreOfPeerPosts
    
FROM 
    FilteredPosts fp
WHERE 
    (fp.UpVotes + COALESCE(fp.UserBadgeCount, 0)) > 5 OR 
    (fp.CommentCount > 10 AND fp.ScoreCategory = 'High Score')
ORDER BY 
    CASE WHEN fp.Score > 100 THEN 1 ELSE 2 END,
    fp.ViewCount DESC,
    fp.CreationDate ASC
FETCH FIRST 50 ROWS ONLY;

This SQL query leverages multiple advanced SQL constructs, including:
1. Common Table Expressions (CTEs) for organizing complex operations.
2. Window functions to rank posts by user.
3. Aggregations and conditional counts for votes and comments.
4. Subqueries to gather additional contextual data (badge count, post history types, linked post counts).
5. Complex predicates that involve conditional logic based on score and comments.
6. Use of `COALESCE` to handle potential NULL values in queries.
7. Ordered results based on defined criteria while limiting results with `FETCH FIRST`.
