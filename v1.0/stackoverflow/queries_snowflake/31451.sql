
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01')
), RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(p.LastActivityDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
), ScoreWithComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        ra.CommentCount,
        ra.LastActivityDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentActivity ra ON rp.PostId = ra.PostId
    WHERE 
        rp.ScoreRank = 1 
), ClosedPostDetails AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
        AND ph.CreationDate >= DATEADD(MONTH, -6, '2024-10-01')
), UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        LISTAGG(b.Name, ', ') WITHIN GROUP (ORDER BY b.Name) AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
), FinalResults AS (
    SELECT 
        sp.Title,
        sp.CreationDate,
        sp.Score,
        sp.ViewCount,
        sp.OwnerDisplayName,
        sp.CommentCount,
        sp.LastActivityDate,
        CASE 
            WHEN cp.PostId IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus,
        ub.TotalBadges
    FROM 
        ScoreWithComments sp
    LEFT JOIN 
        ClosedPostDetails cp ON sp.PostId = cp.PostId
    LEFT JOIN 
        UserBadges ub ON sp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = ub.UserId)
)
SELECT 
    *,
    CASE 
        WHEN TotalBadges > 10 THEN 'Veteran'
        WHEN TotalBadges BETWEEN 5 AND 10 THEN 'Active'
        ELSE 'Newcomer'
    END AS UserCategory
FROM 
    FinalResults
ORDER BY 
    ViewCount DESC, CreationDate DESC
LIMIT 50;
