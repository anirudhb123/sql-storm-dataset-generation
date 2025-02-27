
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate) AS OverallPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
), RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 12 THEN 1 ELSE 0 END) AS SpamVoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 30 DAY)
    GROUP BY 
        v.PostId
), PostHistoryData AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate,
        GROUP_CONCAT(DISTINCT pt.Name ORDER BY pt.Name SEPARATOR ', ') AS PostHistoryTypes
    FROM 
        PostHistory ph
    LEFT JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.CommentCount,
    v.VoteCount,
    v.UpvoteCount,
    v.DownvoteCount,
    h.LastClosedDate,
    h.LastReopenedDate,
    h.PostHistoryTypes,
    CASE 
        WHEN h.LastClosedDate IS NOT NULL AND (h.LastReopenedDate IS NULL OR h.LastClosedDate > h.LastReopenedDate) THEN 'Closed'
        WHEN h.LastReopenedDate IS NOT NULL THEN 'Reopened'
        ELSE 'Active'
    END AS Status,
    CASE 
        WHEN v.UpvoteCount > v.DownvoteCount THEN 'Positive Engagement'
        ELSE 'Needs Attention'
    END AS EngagementStatus,
    CASE 
        WHEN r.UserPostRank = 1 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostRank
FROM 
    RankedPosts r
LEFT JOIN 
    RecentVotes v ON r.PostId = v.PostId
LEFT JOIN 
    PostHistoryData h ON r.PostId = h.PostId
WHERE 
    r.OverallPostRank <= 100
ORDER BY 
    r.Score DESC, r.CreationDate DESC;
