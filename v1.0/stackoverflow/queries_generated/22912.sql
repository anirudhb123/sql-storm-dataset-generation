WITH RelevantPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        pt.Name AS PostType,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
OverlappingTypes AS (
    SELECT
        pt.Id AS PostTypeId,
        STRING_AGG(pt.Name, ', ') AS RelatedTypes
    FROM 
        PostTypes pt
    JOIN 
        PostLinks pl ON pl.LinkTypeId = pt.Id
    GROUP BY 
        pt.Id
)
SELECT 
    p.Title,
    p.ViewCount,
    p.CommentCount,
    p.Score,
    ur.Reputation,
    ur.BadgeCount,
    p.UserPostRank,
    COALESCE(CAST(NULLIF(p.Score, 0) AS VARCHAR), 'No Score') AS Score_Display,
    CASE 
        WHEN p.ViewCount = 0 THEN 'Unseen'
        WHEN p.ViewCount < 100 THEN 'Low Views'
        ELSE 'Popular'
    END AS Popularity,
    ot.RelatedTypes
FROM 
    RelevantPosts p
JOIN 
    UserReputation ur ON p.OwnerUserId = ur.UserId
LEFT JOIN 
    OverlappingTypes ot ON p.PostTypeId = ot.PostTypeId
WHERE 
    (p.Score > 10 OR ur.BadgeCount > 0)
    AND (p.CreationDate LIKE '2023%' OR p.ViewCount IS NOT NULL)
ORDER BY 
    p.Score DESC, 
    ur.Reputation ASC
LIMIT 100
OFFSET 0;

### Explanation
- **Common Table Expressions (CTEs)**:
  - **RelevantPosts**: This CTE fetches relevant posts created in the last year, calculating their score, view count, comment count, and upvote/downvote statistics while adding a rank based on the score for each user.
  - **UserReputation**: It collects user details including their reputation and the count of badges they possess.
  - **OverlappingTypes**: It summarizes related post types through joins on links to understand the relationships between posts better.

- **Main SELECT Query**: It retrieves data from CTEs, showcasing post titles, views, scores, and user reputations. It employs:
  - `COALESCE` and `NULLIF` for score display handling to show 'No Score' if the score is zero.
  - A `CASE` condition to categorize posts based on view counts into 'Unseen', 'Low Views', or 'Popular'.
  
- **Complex WHERE Clause**: It requires posts that have either a score greater than 10 or users with badges and constraints on creation date or view counts.
  
- **Ordering and Pagination**: The results are ordered by score and user reputation, with pagination using LIMIT and OFFSET.
