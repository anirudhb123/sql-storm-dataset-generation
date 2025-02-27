
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
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
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
RecentBadges AS (
    SELECT
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= DATEADD(YEAR, -1, GETDATE())
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
        CASE WHEN rp.CloseCount > 0 THEN 1 ELSE 0 END AS IsClosed,
        CASE WHEN rp.DeleteCount > 0 THEN 1 ELSE 0 END AS IsDeleted
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
        WHEN ps.IsClosed = 1 AND ps.IsDeleted = 1 THEN 'Closed and Deleted' 
        WHEN ps.IsClosed = 1 THEN 'Closed' 
        WHEN ps.IsDeleted = 1 THEN 'Deleted' 
        ELSE 'Active' 
    END AS PostStatus 
FROM 
    PostStatistics ps
WHERE 
    ps.Score >= 0
ORDER BY 
    ps.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
