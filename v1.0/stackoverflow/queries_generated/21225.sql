WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><') AS tag_arr ON TRUE
    LEFT JOIN 
        Tags t ON TRIM(BOTH '<>' FROM tag_arr) = t.TagName
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        COUNT(DISTINCT ph.PostId) AS EditedPostCount,
        ARRAY_AGG(DISTINCT b.Name) AS Badges
    FROM 
        Users u 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    GROUP BY 
        u.Id
),
FinalStats AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score - ps.DownVotes AS NetScore,
        ps.ViewCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.BadgeCount,
        us.Badges
    FROM 
        PostStats ps
    JOIN 
        Users u ON ps.PostId = u.Id AND ps.PostTypeId = 1
    LEFT JOIN 
        UserStats us ON u.Id = us.UserId
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.NetScore,
    fs.ViewCount,
    fs.UpVotes,
    fs.DownVotes,
    fs.CommentCount,
    fs.DisplayName AS OwnerDisplayName,
    fs.Reputation,
    fs.BadgeCount,
    fs.Badges,
    COALESCE(pht.Name, 'No History') AS PostHistoryType
FROM 
    FinalStats fs
LEFT OUTER JOIN 
    PostHistory pht ON fs.PostId = pht.PostId 
                  AND pht.CreationDate = (SELECT MAX(CreationDate) 
                                           FROM PostHistory 
                                           WHERE PostId = fs.PostId)
WHERE 
    fs.NetScore IS NOT NULL 
ORDER BY 
    fs.NetScore DESC, fs.ViewCount DESC
LIMIT 100;

### Explanation:
1. **CTE Overview:**
   - **PostStats:** Computes detailed statistics for each post, including the net score, total views, upvotes, downvotes, and associated tags.
   - **UserStats:** Aggregates user statistics including the number of badges and edited posts.
   - **FinalStats:** Combines post and user statistics for final output formatting.

2. **Joins and Aggregation Logic:**
   - Uses `LEFT JOIN` to ensure all relevant data is captured even if some relationships do not exist (e.g., posts with no comments or votes).
   - Utilizes `STRING_AGG` to concatenate tags while ensuring it handles the potential for multiple entries.

3. **Corner Cases and Unusual Semantics:**
   - The `STRING_TO_ARRAY` is used with `TRIM` functions to avoid issues with leading or trailing characters.
   - Employs an outer join to relate users with the post they own based on the post type, demonstrating the handling of NULL relationships effectively.

4. **Order and Limit:**
   - The results are ordered by calculated net score and view count, which adds a tiered performance metric.
   - The query limits output to 100 records but showcases a wide array of data points suitable for performance benchmarking.

This query is designed for complexity and incorporates various SQL constructs mentioned in the prompt, ensuring it engages with a diverse SQL usage scenario.
