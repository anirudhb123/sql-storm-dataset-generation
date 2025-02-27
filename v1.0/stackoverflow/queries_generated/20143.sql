WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS t(TagName) ON true
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        pht.Name AS HistoryType,
        ph.UserDisplayName,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '6 months'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.Tags,
    us.DisplayName AS TopUser,
    us.UpVotes,
    us.DownVotes,
    COALESCE(phd.HistoryType, 'No Changes') AS LastHistoryType,
    COALESCE(phd.UserDisplayName, 'N/A') AS LastEditor,
    ph.CreationDate AS LastEditDate
FROM 
    RankedPosts rp
LEFT JOIN 
    UserStats us ON us.UserId = (SELECT OwnerUserId FROM Posts p WHERE p.Id = rp.PostId)
LEFT JOIN 
    PostHistoryDetails phd ON phd.PostId = rp.PostId AND phd.HistoryRank = 1
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC NULLS LAST,
    us.UpVotes DESC NULLS FIRST;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - **RankedPosts**: Ranks posts by score and groups them with associated tags.
   - **UserStats**: Aggregates user voting stats and badge counts for users with significant reputations.
   - **PostHistoryDetails**: Captures details of post history changes made in the last six months.

2. **Ranking and Partitions**: Uses the `ROW_NUMBER()` function to provide rankings among posts and history.

3. **Array Aggregation**: Accumulates unique tags related to each post using PostgreSQL's `ARRAY_AGG()` function.

4. **Conditional Aggregation**: Generates aggregated counts for upvotes and downvotes based on vote types.

5. **NULL Logic**: Handles potential NULL values gracefully using `COALESCE` for the last history type and last editor.

6. **Unusual String Manipulations**: Implements the string manipulation for tags by unnesting and manipulating the `Tags` string field in `Posts`.

7. **Order by Semantics**: Uses NULLS LAST and NULLS FIRST in the ORDER BY clause for sorting based on custom criteria.

This query is designed to gather detailed insights into prominent posts, their authors, and changes made, while demonstrating various intricate SQL functionalities that might be useful for performance benchmarking.
