WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
)

SELECT 
    u.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rp.UpVotes IS NULL AND rp.DownVotes IS NULL THEN 'No votes yet'
        ELSE CONCAT_WS(' ', 
            COALESCE(CONCAT('Upvotes:', rp.UpVotes), 'No upvotes'), 
            COALESCE(CONCAT('Downvotes:', rp.DownVotes), 'No downvotes'))
    END AS VoteSummary,
    COALESCE(b.Name, 'No badge') AS BadgeName,
    CASE 
        WHEN (rp.UpVotes - rp.DownVotes) > 0 THEN 'Positive Engagement'
        WHEN (rp.UpVotes - rp.DownVotes) < 0 THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementStatus,
    CASE 
        WHEN rl.PostId IS NOT NULL THEN 'Has Related Post' 
        ELSE 'No Related Post' 
    END AS RelatedPostStatus
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1 -- Gold badges
LEFT JOIN 
    PostLinks rl ON rp.PostId = rl.PostId AND rl.LinkTypeId = 1 -- Linked Posts
WHERE 
    rp.RN = 1
ORDER BY 
    rp.ViewCount DESC 
LIMIT 10;

### Explanation:

1. **CTE:** The query begins with a Common Table Expression (CTE) called `RankedPosts` that calculates the total number of comments, upvotes, and downvotes for questions created within the last year.

2. **LEFT JOINs:** It joins to the `Comments` and `Votes` tables to aggregate relevant metrics.

3. **HAVING Clause:** It restricts results only to questions, grouping by post ID.

4. **Window Functions:** A window function assigns a row number per user based on the post's creation date.

5. **Main Select:** The main selection retrieves user details, post titles, and computed metrics such as vote summaries and engagement statuses.

6. **String Expressions:** It employs string concatenation using `CONCAT_WS` to format the vote summary.

7. **Conditional Logic:** The engagement status and related post status are conditionally determined based on calculated votes and presence in the `PostLinks`.

8. **Badges:** It includes a LEFT JOIN on the `Badges` table to check for users with a gold badge.

9. **Limiting Results:** It uses a `LIMIT` clause to restrict outputs to the top 10 results based on view count.

This query can serve as a performance benchmark for analyzing and retrieving detailed insights about user engagement with posts while demonstrating complex SQL constructs.
