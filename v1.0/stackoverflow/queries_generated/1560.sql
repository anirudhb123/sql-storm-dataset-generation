WITH UserVotes AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY UserId
),
PostAnalytics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVoteCount,
        COALESCE(SUM(c.Score) OVER (PARTITION BY p.Id), 0) AS TotalComments,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY c.CreationDate DESC) AS LatestCommentRank
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR'
),
ClosedPosts AS (
    SELECT 
        PostId,
        COUNT(*) AS ClosureCount
    FROM PostHistory
    WHERE PostHistoryTypeId IN (10, 11) -- Closed and Reopened
    GROUP BY PostId
),
FinalReport AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.OwnerDisplayName,
        pa.CreationDate,
        pa.Score,
        pa.ViewCount,
        pa.UpVoteCount,
        pa.DownVoteCount,
        pa.TotalComments,
        COALESCE(cp.ClosureCount, 0) AS ClosureCount,
        ROW_NUMBER() OVER (ORDER BY pa.Score DESC, pa.ViewCount DESC) AS Rank
    FROM PostAnalytics pa
    LEFT JOIN ClosedPosts cp ON pa.PostId = cp.PostId
)

SELECT 
    *,
    (UpVoteCount - DownVoteCount) AS NetVotes,
    CASE 
        WHEN ClosureCount > 0 THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM FinalReport
WHERE Rank <= 100 -- Top 100 posts
ORDER BY NetVotes DESC, CreationDate DESC;
