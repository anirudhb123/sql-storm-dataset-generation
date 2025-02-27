WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1  -- Filter for Questions only
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasonNames
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY ph.PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes,
        COALESCE(cp.CloseCount, 0) AS CloseCount,
        COALESCE(cp.CloseReasonNames, 'No closure reasons') AS CloseReasonNames,
        CASE
            WHEN rp.Score < 0 THEN 'Needs help'
            WHEN rp.Score >= 0 AND rp.UpVotes > rp.DownVotes THEN 'Getting attention'
            ELSE 'Average'
        END AS PostQuality
    FROM RankedPosts rp
    LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.CloseCount,
    pd.CloseReasonNames,
    pd.PostQuality,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation
FROM PostDetails pd
JOIN Users U ON pd.PostId = U.Id
WHERE pd.UserPostRank <= 3  -- Get only the latest 3 posts per user
ORDER BY pd.PostQuality ASC, pd.Score DESC, pd.CreationDate DESC;

-- Combining results of posts with their closure history, user details, and post ranking.

This SQL query encapsulates performance benchmarking by retrieving and ranking posts, handling closure reasons, calculating basic statistics on votes, and categorizing posts based on their quality while utilizing different SQL constructs like CTEs (Common Table Expressions), correlated subqueries, functions like `STRING_AGG()`, `COALESCE()`, and window functions such as `ROW_NUMBER()`. Additionally, it integrates error handling with score calculations and wraps in a broader context by connecting user information.
