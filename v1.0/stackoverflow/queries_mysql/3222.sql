
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COALESCE(SUM(v.BountyAmount), 0) OVER (PARTITION BY p.OwnerUserId) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COALESCE(SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END), 0) AS PositiveScoreCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id,
        hp.PostId,
        hp.Comment
    FROM 
        PostHistory hp
    JOIN 
        Posts p ON hp.PostId = p.Id
    WHERE 
        hp.PostHistoryTypeId = 10 
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        us.DisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.TotalBounty
    FROM 
        RankedPosts rp
    JOIN 
        UserStats us ON rp.OwnerUserId = us.UserId
    WHERE 
        rp.RankByScore <= 5
)
SELECT 
    tp.Title,
    tp.DisplayName,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.TotalBounty,
    COALESCE(cp.Comment, 'No closure comment') AS ClosureComment
FROM 
    TopPosts tp
LEFT JOIN 
    ClosedPosts cp ON tp.Id = cp.PostId
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
