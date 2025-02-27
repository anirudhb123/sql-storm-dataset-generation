WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate < NOW() - INTERVAL '6 months'
    GROUP BY 
        p.Id, u.DisplayName
), 
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate AS ClosedDate,
        STRING_AGG(pt.Name, ', ') AS CloseReasons
    FROM 
        Posts p 
    INNER JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) 
    LEFT JOIN 
        CloseReasonTypes pt ON ph.Comment::int = pt.Id
    WHERE 
        ph.CreationDate < NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, ph.CreationDate
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.Id,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.CommentCount,
    cp.ClosedDate,
    cp.CloseReasons,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.Id
LEFT JOIN 
    UserStats us ON rp.OwnerDisplayName = us.DisplayName
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
