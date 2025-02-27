
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpvoteCount, 
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownvoteCount 
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR) 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, u.DisplayName, p.PostTypeId
),
PostStatistics AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CreationDate,
        OwnerDisplayName,
        Rank,
        UpvoteCount,
        DownvoteCount,
        (UpvoteCount - DownvoteCount) AS NetVotes, 
        CASE WHEN Score > 100 THEN 'High' 
             WHEN Score BETWEEN 50 AND 100 THEN 'Medium' 
             ELSE 'Low' END AS ScoreCategory 
    FROM 
        RankedPosts
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(ct.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes ct ON CAST(ph.Comment AS UNSIGNED) = ct.Id 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.CreationDate,
    ps.OwnerDisplayName,
    ps.Rank,
    ps.NetVotes,
    ps.ScoreCategory,
    COALESCE(cp.CloseReasons, 'Not Closed') AS CloseReason
FROM 
    PostStatistics ps
LEFT JOIN 
    ClosedPosts cp ON ps.PostId = cp.PostId
WHERE 
    ps.Rank <= 5 
ORDER BY 
    ps.Score DESC, ps.CreationDate DESC;
