WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS ScoreRank,
        DENSE_RANK() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS ViewCountRank
    FROM 
        Posts p
        JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
UserInteractions AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT v.PostId) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
        LEFT JOIN Votes v ON u.Id = v.UserId
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(ui.VoteCount, 0) AS TotalVotes,
        ui.UpvoteCount,
        ui.DownvoteCount,
        CASE 
            WHEN ui.UpvoteCount IS NULL AND ui.DownvoteCount IS NULL THEN 'No Votes'
            ELSE 'Votes Present'
        END AS VoteStatus
    FROM 
        RankedPosts rp
        LEFT JOIN UserInteractions ui ON rp.OwnerUserId = ui.UserId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.TotalVotes,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.VoteStatus,
    CASE 
        WHEN ps.ScoreRank <= 5 THEN 'Top 5 Posts'
        WHEN ps.ViewCountRank <= 5 THEN 'Top 5 Viewed Posts'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    PostStatistics ps
WHERE 
    ps.Score > (SELECT AVG(Score) FROM Posts WHERE Score IS NOT NULL)
    AND ps.VoteStatus = 'Votes Present'
ORDER BY 
    ps.Score DESC,
    ps.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;

-- Additional complex constructs
SELECT 
    COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.PostId END) AS ClosedPostsCount,
    COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.PostId END) AS ReopenedPostsCount,
    AVG(length(p.Body)) AS AvgBodyLength,
    STRING_AGG(DISTINCT CONCAT(u.DisplayName, ' (', u.Reputation, ')'), '; ') AS ActiveUsers
FROM 
    PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    JOIN Users u ON p.OwnerUserId = u.Id
WHERE 
    ph.CreationDate > NOW() - INTERVAL '6 months'
    AND u.Reputation > 100
HAVING 
    COUNT(DISTINCT ph.PostId) > 5
;
