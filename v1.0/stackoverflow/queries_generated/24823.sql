WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalCount
    FROM
        Posts p
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score > 0
),
PostVotes AS (
    SELECT
        v.PostId,
        vt.Name AS VoteType,
        COUNT(v.Id) AS VoteCount
    FROM
        Votes v
    JOIN
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY
        v.PostId, vt.Name
),
FilteredPostVotes AS (
    SELECT
        pv.PostId,
        SUM(CASE WHEN pv.VoteType = 'UpMod' THEN pv.VoteCount ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN pv.VoteType = 'DownMod' THEN pv.VoteCount ELSE 0 END) AS DownVotes
    FROM
        PostVotes pv
    GROUP BY
        pv.PostId
),
TopRatedPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.TotalCount,
        COALESCE(fp.UpVotes, 0) AS UpVotes,
        COALESCE(fp.DownVotes, 0) AS DownVotes
    FROM
        RankedPosts rp
    LEFT JOIN
        FilteredPostVotes fp ON rp.PostId = fp.PostId
    WHERE
        rp.rn <= 5
)
SELECT
    trp.PostId,
    trp.Title,
    trp.TotalCount,
    trp.UpVotes,
    trp.DownVotes,
    CASE
        WHEN trp.UpVotes + trp.DownVotes > 0 THEN
            ROUND((trp.UpVotes * 1.0 / (trp.UpVotes + trp.DownVotes)) * 100, 2)
        ELSE 0
    END AS UpVotePercentage,
    CASE
        WHEN EXISTS (SELECT 1 FROM PostHistory ph WHERE ph.PostId = trp.PostId AND ph.PostHistoryTypeId = 10) THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM
    TopRatedPosts trp
ORDER BY
    trp.UpVotes DESC NULLS LAST,
    trp.DownVotes ASC NULLS FIRST;

### Explanation:
1. **CTEs**: The query uses multiple Common Table Expressions (CTEs) to organize data logically.
   - `RankedPosts`: Ranks posts in the last year by their creation date (most recent at the top) while filtering for positive scores, categorizing them by `PostTypeId`.
   - `PostVotes`: Aggregates the total votes of each type for the posts.
   - `FilteredPostVotes`: Computes separate counts for upvotes and downvotes.
   - `TopRatedPosts`: Combines ranked posts with their voting statistics, limiting to the top 5 posts per type.

2. **Main Select Statement**: The final selection shows the PostId, Title, number of votes, and calculates the upvote percentage; it also includes a status check to see if the post is closed or active using a correlated subquery.

3. **Unusual Logic**: The use of COALESCE for NULL handling, division for percentage calculation (with rounding), and a case statement for determining post status introduces complexity in the query.

4. **Ordering Logic**: Posts are ordered first by UpVotes (descending), then DownVotes (ascending) which integrates sorting based on vote dynamics.

5. **NULL Logic**: Explicit handling of scenarios where posts may have no votes, ensuring no division by zero occurs. 

The query focuses on performance benchmarking by using a combination of analytical functions, subqueries, and conditionals, while adhering to possible real-world cases you may encounter.
