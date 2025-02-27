WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserVoteSummary AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT v.PostId) AS UniqueVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
)
SELECT 
    u.DisplayName,
    COALESCE(SUM(CASE WHEN bp.Rank <= 10 THEN 1 ELSE 0 END), 0) AS TopPostCount,
    COALESCE(SUM(CASE WHEN bp.Rank <= 10 THEN bp.ViewCount ELSE 0 END), 0) AS TopPostViews,
    v.TotalUpvotes,
    v.TotalDownvotes,
    v.UniqueVotes,
    CASE 
        WHEN v.TotalUpvotes > v.TotalDownvotes THEN 'Positively Influential'
        WHEN v.TotalDownvotes > v.TotalUpvotes THEN 'Negatively Influential'
        ELSE 'Neutral'
    END AS InfluenceType
FROM 
    Users u
LEFT JOIN 
    RankedPosts bp ON u.Id = bp.OwnerUserId
LEFT JOIN 
    UserVoteSummary v ON u.Id = v.UserId
WHERE 
    u.Reputation > 100
GROUP BY 
    u.DisplayName, v.TotalUpvotes, v.TotalDownvotes, v.UniqueVotes
ORDER BY 
    TopPostViews DESC, u.DisplayName ASC
LIMIT 100;

This SQL query performs the following interesting and elaborate operations:

1. **Common Table Expressions (CTEs):** It uses two CTEs:
   - `RankedPosts` to rank posts based on view counts for each post type in the last year while also calculating the comment count.
   - `UserVoteSummary` to summarize user votes, counting total upvotes, downvotes, and unique posts voted on.

2. **Outer Joins:** It employs left joins to include users who may not have any posts or votes related to them.

3. **Window Functions:** The `ROW_NUMBER()` function is used in `RankedPosts` to assign ranks to posts based on their view count.

4. **Conditional Aggregations:** The use of `CASE` statements for aggregating votes and determining influence helps handle various conditions succinctly.

5. **COALESCE:** This function ensures that even if there are no top posts for a user or no votes recorded, a count of 0 is returned instead of NULL.

6. **Complicated Predicates and Expressions:** It filters users based on reputation and groups the results, providing dynamic analysis based on user activity and engagement.

7. **Bizarre SQL Semantics:** It introduces a dynamic category for users ('InfluenceType') based on the proportion of upvotes to downvotes, showcasing the various statistical analyses possible within SQL. 

This query not only benchmarks performance across various joins and expressions but also provides insights into user activity and post engagement.
