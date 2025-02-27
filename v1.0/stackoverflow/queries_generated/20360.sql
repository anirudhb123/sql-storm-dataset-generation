WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        pvc.UpVotes,
        pvc.DownVotes,
        ub.BadgeCount,
        ub.HighestBadgeClass,
        CASE
            WHEN ur.Rank <= 5 THEN 'Top 5 Posts'
            ELSE 'Other Posts'
        END AS TopCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteCounts pvc ON rp.PostId = pvc.PostId
    LEFT JOIN 
        Users ur ON rp.OwnerUserId = ur.Id
    LEFT JOIN 
        UserBadges ub ON ur.Id = ub.UserId
    WHERE 
        rp.Rank <= 10 AND (ub.BadgeCount > 0 OR pvc.UpVotes > 0)
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.UpVotes,
    pp.DownVotes,
    pp.BadgeCount,
    pp.HighestBadgeClass,
    pp.TopCategory,
    COALESCE(ROUND((pp.UpVotes::NUMERIC / NULLIF(pp.UpVotes + pp.DownVotes, 0)) * 100, 2), 0) AS UpvotePercentage
FROM 
    PopularPosts pp
ORDER BY 
    pp.ViewCount DESC, pp.UpVotes DESC
LIMIT 20;

### Explanation of the Query Elements:

1. **Common Table Expressions (CTEs):**
   - **RankedPosts:** Ranks posts per user based on their creation date and includes a count of comments for each post.
   - **PostVoteCounts:** Calculates total upvotes and downvotes for each post.
   - **UserBadges:** Counts badges for users and determines the highest badge class they hold.
   - **PopularPosts:** Joins the previous CTEs, filters for top-ranked posts, and categorizes each post into 'Top 5 Posts' or 'Other Posts'.

2. **Correlated Subqueries and Complex Joins:** 
   - The query utilizes left joins to aggregate data from multiple tables and forms relationships between users and their posts.

3. **Window Functions:**
   - The `ROW_NUMBER()` function is used to rank posts within partitions defined by the `OwnerUserId`.

4. **String Expressions and Calculations:**
   - The final select statement computes the upvote percentage with proper handling of division by zero using the `NULLIF()` function.

5. **NULL Logic:**
   - `COALESCE` is employed to manage potential null values in the calculation of the upvote percentage.

6. **Use of Case Statement:**
   - A case statement categorizes posts based on their rank in the overall results.

7. **Bizarre SQL Semantics:**
   - The query recognizes and filters popular posts, emphasizing posts that have user interaction through votes or badges, creating an intricate logic of user engagement on the platform. 

This query serves as a performance benchmarking example that integrates various SQL constructs while ensuring complexity and depth.
