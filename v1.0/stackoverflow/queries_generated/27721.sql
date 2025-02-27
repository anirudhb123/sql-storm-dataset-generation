WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
MostVotedPosts AS (
    SELECT 
        pv.PostId,
        COUNT(*) AS VoteCount
    FROM 
        Votes pv
    GROUP BY 
        pv.PostId
    HAVING 
        COUNT(*) >= 10
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        MAX(b.Class) AS BestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        ub.TotalBadges,
        ub.BestBadgeClass
    FROM 
        RankedPosts rp
    JOIN 
        MostVotedPosts mv ON rp.PostId = mv.PostId
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        rp.Rank <= 10 
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.TotalBadges,
    CASE 
        WHEN tp.BestBadgeClass = 1 THEN 'Gold'
        WHEN tp.BestBadgeClass = 2 THEN 'Silver'
        WHEN tp.BestBadgeClass = 3 THEN 'Bronze'
        ELSE 'No Badge'
    END AS BestBadge
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC, 
    tp.TotalBadges DESC;
