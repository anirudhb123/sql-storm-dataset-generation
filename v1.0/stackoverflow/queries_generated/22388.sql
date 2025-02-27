WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  -- Only Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.PostRank,
        CASE 
            WHEN rp.PostRank = 1 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS PostCategory,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.PostId = u.Id  -- Join with users to get the owner's display name
    WHERE 
        rp.PostRank <= 5  -- Top 5 posts per type
),
BadgesCount AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
FinalResults AS (
    SELECT 
        t.Title,
        t.CreationDate,
        t.Score,
        t.ViewCount,
        t.PostCategory,
        COALESCE(b.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(b.BadgeNames, 'No Badges') AS UserBadges
    FROM 
        TopPostDetails t
    LEFT JOIN 
        BadgesCount b ON t.PostId = b.UserId  -- Join Badges count to posts
)
SELECT 
    f.Title,
    f.CreationDate,
    f.Score,
    f.ViewCount,
    f.PostCategory,
    f.UserBadgeCount,
    f.UserBadges
FROM 
    FinalResults f
WHERE 
    f.Score > 10 AND 
    f.UserBadgeCount IS NOT NULL
ORDER BY 
    f.Score DESC, 
    f.CreationDate ASC
LIMIT 10;

### Explanation:
- This query starts with a Common Table Expression (CTE) `RankedPosts` to calculate the ranking of posts based on score within their respective post types (Questions and Answers) for posts created in the last year. It also counts the number of comments and votes for each post.
  
- The `TopPostDetails` CTE filters the top 5 posts per type and assigns a category to each (Top Post or Regular Post). It aggregates display names for owners from the Users table.

- A third CTE `BadgesCount` calculates how many badges each user has and creates a concatenated string of badge names.

- The final CTE `FinalResults` joins the previous results to gather necessary fields and counts into one combined output.

- The final SELECT statement filters results to only those with a score greater than 10 and includes users who have badges, ordering the results by score and creation date, and limiting to 10 results.

This query utilizes outer joins, CTEs, window functions, string aggregations, and complex predicates to produce results that may reveal interesting trends in user engagement and content quality.
