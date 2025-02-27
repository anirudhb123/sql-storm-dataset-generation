WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePostCount,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews,
        SUM(COALESCE(p.UpVotes, 0)) - SUM(COALESCE(p.DownVotes, 0)) AS NetVotes,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(p.UpVotes, 0)) - SUM(COALESCE(p.DownVotes, 0)) DESC) AS VoteRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        PositivePostCount,
        NegativePostCount,
        AvgViews,
        NetVotes,
        VoteRank,
        ROW_NUMBER() OVER (ORDER BY VoteRank) AS RowNum
    FROM 
        UserPostStats
    WHERE 
        PostCount > 0
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS VoteCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        p.ViewCount,
        (CASE 
            WHEN p.CreationDate < NOW() - INTERVAL '1 year' THEN 'Old Post'
            ELSE 'New Post'
        END) AS PostAge
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
            PostId, COUNT(*) AS CommentCount 
         FROM 
            Comments 
         GROUP BY 
            PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT 
            PostId, COUNT(*) AS VoteCount 
         FROM 
            Votes 
         GROUP BY 
            PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT 
            UserId, COUNT(*) AS BadgeCount 
         FROM 
            Badges 
         GROUP BY 
            UserId) b ON p.OwnerUserId = b.UserId
)
SELECT 
    TOPU.UserId,
    TOPU.DisplayName,
    TOPU.PostCount,
    TOPU.PositivePostCount,
    TOPU.NegativePostCount,
    TOPU.AvgViews,
    TOPU.NetVotes,
    PP.PostId,
    PP.Title,
    PP.CreationDate,
    PP.CommentCount,
    PP.VoteCount,
    PP.BadgeCount,
    PP.ViewCount,
    PP.PostAge
FROM 
    TopUsers TOPU
JOIN 
    TopPosts PP ON TOPU.UserId = PP.OwnerUserId
WHERE 
    TOPU.VoteRank <= 5 
ORDER BY 
    TOPU.NetVotes DESC,
    PP.VoteCount DESC;

### Explanation of the Query:

1. **Common Table Expressions (CTEs):**
   - `UserPostStats`: Gathers statistics for users, calculating post counts, positive/negative post counts, average views, and net votes.
   - `TopUsers`: Filters `UserPostStats` to find the top users based on their net votes and ranks them.
   - `TopPosts`: Aggregates post details, such as the comment count, vote count, and badge count for each post.

2. **Outer Joins**: Used to ensure that users with no posts are still included in the stats, and all post-related aggregates can show zero counts when no data exists.

3. **Window Functions**: Utilized for ranking users and posts based on their scores.

4. **Case Statements**: Display whether a post is "Old" or "New" depending on its creation date relative to 1 year from now.

5. **Complicated Predicates**: Involves several aggregates and conditions filtering for only users with a positive number of posts and showcasing the top ones based on varying criteria.

6. **NULL Logic**: Makes use of `COALESCE` to handle NULLs while computing average views, vote counts, and badge counts.

This SQL query structure allows for performance benchmarking and testing complex SQL logic while utilizing a rich dataset for analytics.
