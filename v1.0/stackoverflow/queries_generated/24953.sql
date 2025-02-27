WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC) AS RankByComments,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE 
            WHEN rp.RankByComments <= 5 THEN 'Top 5 in Category'
            ELSE 'Other'
        END AS CommentRankCategory,
        Users.DisplayName AS OwnerName
    FROM 
        RankedPosts rp
    JOIN 
        Users ON rp.OwnerUserId = Users.Id
),
PostHistoryDetail AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId = 53 THEN ph.CreationDate END) AS LastRemovedHot,
        MAX(CASE WHEN ph.PostHistoryTypeId = 52 THEN ph.CreationDate END) AS LastAddedHot
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    COALESCE(phd.LastClosed, 'Never Closed') AS LastClosed,
    COALESCE(phd.LastRemovedHot, 'Never Removed') AS LastRemovedHot,
    COALESCE(phd.LastAddedHot, 'Never Added') AS LastAddedHot,
    tp.OwnerName,
    CASE 
        WHEN tp.CommentRankCategory = 'Top 5 in Category' THEN 'Featured'
        ELSE 'Regular'
    END AS PostType
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistoryDetail phd ON tp.PostId = phd.PostId
ORDER BY 
    tp.UpVoteCount DESC, tp.CommentCount DESC
LIMIT 100;

In this SQL query, we are analyzing posts from a Stack Overflow-like schema while incorporating several advanced SQL features:

1. **Common Table Expressions (CTEs)**:
   - `RankedPosts`: This CTE ranks posts based on the number of comments made in the past year and also determines the number of upvotes and downvotes each post has received.
   - `TopPosts`: This CTE categorizes posts into 'Top 5 in Category' or 'Other' based on their comment ranking, while also fetching the owner's display name.
   - `PostHistoryDetail`: This CTE aggregates post history to find the most recent relevant events (like when the post was closed or marked as hot).

2. **Window Functions**: Used to rank the posts based on the comment count and help categorize them based on their ranks.

3. **LEFT JOINs**: To fetch associated comments and votes without excluding posts that don't have them.

4. **Conditional Aggregates**: Counting upvotes and downvotes using CASE statements.

5. **COALESCE Function**: To handle NULL logic, providing default messages for the last closed date, last removed hot status, and last added hot status.

6. **ORDER BY and LIMIT**: To return the top 100 posts based on upvote counts and then by comment counts in case of ties.

The result provides a structured report of the top posts, including their engagement statistics and history of important status changes, suitable for performance benchmarking while also demonstrating complex SQL capabilities.
