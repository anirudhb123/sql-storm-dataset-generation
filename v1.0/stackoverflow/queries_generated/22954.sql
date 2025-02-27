WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COUNT(v.Id) OVER (PARTITION BY p.Id, v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) OVER (PARTITION BY p.Id, v.VoteTypeId = 3) AS DownVoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON true
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        rp.RankByScore,
        CASE
            WHEN rp.CommentCount > 0 THEN 'Has Comments'
            ELSE 'No Comments'
        END AS CommentStatus,
        COALESCE(NULLIF(rp.UpVoteCount, 0), -1) AS UpVoteStatus,
        COALESCE(NULLIF(rp.DownVoteCount, 0), -1) AS DownVoteStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 5 AND
        (rp.Score > 0 OR rp.ViewCount > 100)
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.Tags,
    fp.CommentStatus,
    CASE 
        WHEN fp.UpVoteStatus < 0 THEN 'No upvotes'
        ELSE CONCAT(fp.UpVoteStatus, ' upvotes')
    END AS UpVotesInfo,
    CASE 
        WHEN fp.DownVoteStatus < 0 THEN 'No downvotes'
        ELSE CONCAT(fp.DownVoteStatus, ' downvotes')
    END AS DownVotesInfo,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM PostHistory ph
            WHERE ph.PostId = fp.PostId 
              AND ph.PostHistoryTypeId IN (10, 11) 
              AND ph.CreationDate > CURRENT_DATE - INTERVAL '1 week'
        ) THEN 'Recently Closed/Reopened'
        ELSE 'Active'
    END AS PostStatus
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.CreationDate DESC;

### Explanation:
1. **CTEs (Common Table Expressions)**: First, `RankedPosts` aggregates information about posts created in the last 30 days, counting associated comments and votes. Tags are processed using `unnest` and `string_to_array`. The `ROW_NUMBER` function ranks posts by `Score` per user.

2. **Filtering Logic**: In `FilteredPosts`, only top-ranked posts (based on score) with at least some engagement (either score more than zero or significant views) are retained.

3. **Complex Case Logic**:
   - The `CommentStatus` identifies posts with or without comments using a `CASE` statement.
   - For upvotes and downvotes, values default to `-1` if there are none, showcasing the power of `COALESCE` and `NULLIF`.

4. **Final Selection and Ordering**: The final query selects refined post information, including user-friendly descriptions for upvotes and downvotes. It also checks the post's history to determine if it has been closed or reopened recently.

5. **Bizarre Semantic Corners**: Usage of `EXISTS` for checking recent modifications in `PostHistory` highlights a nuanced consideration of state changes in post lifecycle. 

This SQL query is designed for performance testing, exploring multiple SQL constructs, while focusing on user-centric metrics from a structured data schema.
