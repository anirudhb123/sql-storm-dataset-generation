WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.PostTypeId
),
TopPosts AS (
    SELECT
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.Rank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.Id) AS CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        Rank <= 10
),
PopularUsers AS (
    SELECT
        u.Id,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id) AS PostCount,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount
    FROM 
        Users u
    WHERE 
        u.Reputation > (SELECT AVG(Reputation) FROM Users)
)
SELECT 
    tp.Title AS PopularPostTitle,
    tp.CreationDate AS PostCreated,
    pu.DisplayName AS UserDisplayName,
    pu.Reputation AS UserReputation,
    tp.CommentCount AS TotalComments,
    COALESCE((SELECT STRING_AGG(CAST(DISTINCT t.TagName AS varchar), ', ') 
              FROM Tags t 
              JOIN Posts_tags pt ON t.Id = pt.TagId 
              WHERE pt.PostId = tp.Id), 'No Tags') AS TagList
FROM 
    TopPosts tp
LEFT JOIN 
    PopularUsers pu ON tp.OwnerUserId = pu.Id
WHERE 
    EXISTS (SELECT 1 FROM PostHistory ph WHERE ph.PostId = tp.Id AND ph.PostHistoryTypeId IN (10, 11))
ORDER BY 
    tp.CommentCount DESC, tp.CreationDate ASC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;

This complex SQL query consists of several components:

1. **Common Table Expressions (CTEs)**: Used to rank posts by their upvotes and downvotes, identify the top posts, and profile popular users.
   
2. **Window Functions**: `ROW_NUMBER()` is applied to get a ranking of posts within their respective types based on the difference between upvotes and downvotes.

3. **Subqueries**: Included to count comments per post, calculate post counts and badge counts for users, and gather tag lists associated with each post.

4. **Outer Joins**: Utilizes `LEFT JOIN` to account for posts that may not have corresponding votes or related records in other tables.

5. **Conditional Logic**: Uses `COALESCE` to handle nulls and ensure the output is user-friendly (showing 'No Tags' when applicable).

6. **String Aggregation**: `STRING_AGG` is used to concatenate tags for each post into a readable format.

7. **Filtered Results and Pagination**: A filter on the existence of specific post history actions and limits the output to the top 5 results sorted by comment count and creation date. 

This query is designed for performance benchmarking, challenging various SQL constructs while ensuring robustness in handling potential edge cases.
