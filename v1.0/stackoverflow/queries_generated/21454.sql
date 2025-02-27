WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
),

UserVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVoteCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),

PostCommentStats AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    u.DisplayName AS OwnerDisplayName,
    rp.CreationDate,
    COALESCE(uv.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(uv.DownVoteCount, 0) AS DownVoteCount,
    COALESCE(uv.TotalBounty, 0) AS TotalBounty,
    COALESCE(cs.CommentCount, 0) AS CommentCount,
    COALESCE(cs.LastCommentDate, 'No Comments') AS LastCommentDate,
    CASE 
        WHEN rp.RN = 1 THEN 'Latest Post by User'
        ELSE 'Older Posts by User'
    END AS PostRank
FROM 
    RankedPosts rp
LEFT JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserVotes uv ON rp.PostId = uv.PostId
LEFT JOIN 
    PostCommentStats cs ON rp.PostId = cs.PostId
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND (uv.UpVoteCount - uv.DownVoteCount) > 0
    AND (rp.CreationDate > (CURRENT_DATE - INTERVAL '3 months') OR cs.CommentCount > 0)
ORDER BY 
    UpVoteCount DESC, 
    rp.CreationDate DESC_nulls_last;

This query performs several tasks:
1. It defines three Common Table Expressions (CTEs):
   - `RankedPosts`: Ranks posts per user based on creation date within the last year.
   - `UserVotes`: Aggregates user votes per post, counting upvotes and downvotes, and summing any bounty amounts.
   - `PostCommentStats`: Counts comments per post and tracks the date of the last comment.
   
2. The main selection retrieves relevant data from these CTEs and joins with the `Users` table to get user display names.

3. Filters are applied based on user reputation, ensuring that only posts from users above the average reputation are included.

4. The query conditions also ensure that only posts with a positive net vote difference or recent activity are included.

5. The results are ordered by the number of upvotes and the creation date of the posts. Lastly, it provides a ranking indicator for the latest post by user. 

This elaborate query showcases various SQL constructs including CTEs, window functions, subqueries, and complex criteria for filtering results.
