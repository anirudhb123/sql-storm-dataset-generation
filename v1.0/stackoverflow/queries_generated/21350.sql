WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.PostId) > 10
),
RecentVoteInfo AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        COUNT(v.VoteTypeId) as VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY 
        v.PostId, v.VoteTypeId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        RANK() OVER (ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    pt.TagName,
    COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
    cp.CloseRank
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON rp.PostId = pt.PostId
LEFT JOIN 
    RecentVoteInfo rv ON rv.PostId = rp.PostId
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.PostId AND cp.CloseRank <= 5  -- Top 5 most recent closed
WHERE 
    rp.PostRank <= 10 -- Top 10 posts by score in each type
ORDER BY 
    rp.CreationDate DESC, 
    rp.Score DESC
LIMIT 50;

### Explanation of the Query Constructs:
- **Common Table Expressions (CTEs)**: The query utilizes multiple CTEs (`RankedPosts`, `PopularTags`, `RecentVoteInfo`, `ClosedPosts`) to break down the complex logic into manageable sections; each CTE has a unique purpose related to posts, tags, votes, and post closures.
- **Window Functions**: `RANK()` is applied to rank posts based on their score and to rank closed posts by their closure date.  
- **Outer Joins**: The main select uses LEFT JOINs to include information from tags, recent votes, and closed posts, ensuring that even if there are gaps (like a post with no votes), the result set maintains all rows from `RankedPosts`.
- **Subqueries/Correlated Subqueries**: The tags are filtered inside the CTE `PopularTags`, aggregating posts to only consider tags with a significant amount of engagement.
- **Set Operators**: Used in filters where conditions aggregate and intersect different relationships in the tables.
- **NULL Logic**: `COALESCE` is used to handle potential NULL values, such as when a post has no owner or no recent votes.
- **Complicated Predicates**: The query incorporates various filter conditions, such as time intervals for posts and votes, to create robust and dynamic filtering.
