WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.CreationDate >= p.CreationDate
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.RowNum <= 5
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(b.Class) AS TotalBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    ub.UserId,
    ub.BadgeCount,
    ub.TotalBadgeClass,
    CASE 
        WHEN ub.BadgeCount IS NULL THEN 'No Badges'
        WHEN ub.BadgeCount > 10 THEN 'Expert'
        ELSE 'Novice'
    END AS UserLevel,
    COALESCE((
        SELECT 
            STRING_AGG(pt.Name, ', ') 
        FROM 
            PostHistory ph
        JOIN 
            PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
        WHERE 
            ph.PostId = fp.PostId AND pht.Name ILIKE '%edit%'
    ), 'No Edits') AS RecentEdits
FROM 
    FilteredPosts fp
LEFT JOIN 
    UserBadges ub ON fp.PostId IN (SELECT DISTINCT p.Id FROM Posts p WHERE p.OwnerUserId = ub.UserId)
ORDER BY 
    fp.CreationDate DESC;
