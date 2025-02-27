
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        @row_number := IF(@prev_user = p.OwnerUserId, @row_number + 1, 1) AS UserPostRank,
        @prev_user := p.OwnerUserId,
        COUNT(v.Id) AS VoteCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 ELSE 0 END) AS DeleteCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_user := NULL) AS vars
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
RecentBadges AS (
    SELECT
        b.UserId,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= CURDATE() - INTERVAL 1 YEAR
    GROUP BY 
        b.UserId
),
PostStatistics AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.VoteCount,
        rp.CommentCount,
        rb.BadgeNames,
        rb.BadgeCount,
        (rp.CloseCount > 0) AS IsClosed,
        (rp.DeleteCount > 0) AS IsDeleted
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentBadges rb ON rp.OwnerUserId = rb.UserId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.VoteCount,
    ps.CommentCount,
    COALESCE(ps.BadgeNames, 'No Badges') AS BadgeNames,
    ps.BadgeCount,
    ps.IsClosed,
    ps.IsDeleted,
    CASE 
        WHEN ps.IsClosed = TRUE AND ps.IsDeleted = TRUE THEN 'Closed and Deleted' 
        WHEN ps.IsClosed = TRUE THEN 'Closed' 
        WHEN ps.IsDeleted = TRUE THEN 'Deleted' 
        ELSE 'Active' 
    END AS PostStatus 
FROM 
    PostStatistics ps
WHERE 
    ps.Score >= 0
ORDER BY 
    ps.CreationDate DESC
LIMIT 100;
