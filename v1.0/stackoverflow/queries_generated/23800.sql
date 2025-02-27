WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS NetVotes, -- Upvotes minus downvotes
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(p.Tags, '<>,>')) AS TagName
        ) t ON TRUE
    WHERE 
        p.PostTypeId IN (1, 2) -- Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.PostTypeId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    rp.RankByDate,
    rp.CommentCount,
    rp.NetVotes,
    rp.TagsList,
    cp.ClosedDate,
    cp.ClosedBy,
    cp.CloseReason
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    (rp.RankByDate <= 5 AND cp.ClosedDate IS NOT NULL) OR 
    (rp.NetVotes > 10 AND cp.ClosedDate IS NULL)
ORDER BY 
    CASE WHEN cp.ClosedDate IS NOT NULL THEN 0 ELSE 1 END, -- Prioritize closed posts
    rp.Score DESC,
    rp.CreationDate DESC
LIMIT 50;


This SQL query performs the following actions:

1. **Common Table Expressions (CTEs)**: It uses two CTEs: `RankedPosts` for ranking posts by creation date within each post type, tracking their scores, comment counts, net votes, and associated tags; the second, `ClosedPosts`, retrieves closed posts, their closure date, the user who closed them, and the closure reason.

2. **Window Functions**: The query applies the `ROW_NUMBER()` window function to establish a rank based on creation date and groups posts by their type.

3. **Lateral Join**: A lateral join is used to split the `Tags` column into a list of individual tags, useful for aggregation.

4. **Conditional Aggregation**: It calculates the net votes for each post (upvotes minus downvotes) using conditional sum functions.

5. **Complicated Predicates**: The final selection criteria specify that it should return posts that are either among the top 5 most recent posts of their type that are closed or have more than 10 net votes and are not closed.

6. **Ordering Logic**: It prioritizes closed posts over open ones in the ordering clause, sorting within those groups by score and creation date.

7. **Distinct Aggregation**: Tags are aggregated using `STRING_AGG`, ensuring they are distinct for clarity.

This complex query thus serves as a performance benchmark through its varied constructs, showcasing both technical capabilities and logical depth in handling the analysis of the Stack Overflow-like database schema.
