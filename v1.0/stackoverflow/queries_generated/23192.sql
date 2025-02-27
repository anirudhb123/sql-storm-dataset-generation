WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.AnswerCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.ViewCount IS NOT NULL
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        b.Name AS BadgeName,
        b.Class,
        COUNT(b.Id) AS BadgeCount,
        ARRAY_AGG(DISTINCT b.Name) AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, b.Class
),
VotesSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(v.Id) FILTER (WHERE vt.Name IS NOT NULL) AS TotalVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
PostInfo AS (
    SELECT 
        rp.PostId,
        rp.Title,
        COALESCE(vs.Upvotes, 0) AS Upvotes,
        COALESCE(vs.Downvotes, 0) AS Downvotes,
        (COALESCE(vs.Upvotes, 0) - COALESCE(vs.Downvotes, 0)) AS NetVotes,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        RankedPosts rp
    LEFT JOIN 
        VotesSummary vs ON rp.PostId = vs.PostId
    LEFT JOIN 
        UserBadges ub ON ub.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    WHERE 
        rp.Rank <= 10
)

SELECT 
    pi.PostId,
    pi.Title,
    pi.Upvotes,
    pi.Downvotes,
    pi.NetVotes,
    pi.BadgeCount,
    pi.BadgeNames,
    CASE 
        WHEN pi.NetVotes < 0 THEN 'Needs Improvement'
        WHEN pi.NetVotes BETWEEN 0 AND 10 THEN 'Moderately Engaging'
        ELSE 'Highly Engaging'
    END AS EngagementLevel,
    CONCAT('Post Score: ', pi.Score, ' | Answer Count: ', pi.AnswerCount) AS PostDetails
FROM 
    PostInfo pi
ORDER BY 
    pi.NetVotes DESC, 
    pi.Upvotes DESC;

This query incorporates common advanced SQL constructs and uses them creatively:

1. **Common Table Expressions (CTEs)**: Several CTEs handle ranking posts, summarizing votes, and aggregating badges, promoting clear modularity in logic.

2. **Window Functions**: The `ROW_NUMBER()` function is used to rank posts within their respective types based on their score and answer count.

3. **Correlated Subqueries**: A subquery retrieves the `OwnerUserId` per post to associate badges with the respective posts.

4. **CASE Expressions**: Custom labels for engagement status based on the net vote count.

5. **String Aggregation and Coalescence**: Use of `ARRAY_AGG` to gather badge names and `COALESCE` for handling NULL values gracefully.

6. **Complicated Predicates**: The logic constructs a rich context using both aggregation and specifics of user interaction with posts.

7. **NULL Logic**: Emphasizes how NULLs are dealt with effectively in counting badges and votes.

8. **Ordering**: The final output orders posts by net votes and upvotes, showing the most engaging posts prominently.

This type of query provides a benchmark for both performance and complexity, showcasing various SQL features and nuanced understanding of the underlying data model.
