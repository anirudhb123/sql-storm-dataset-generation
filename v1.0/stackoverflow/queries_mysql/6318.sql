
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        @row_number := IF(@prev_post_type_id = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_type_id := p.PostTypeId
    FROM 
        Posts p, (SELECT @row_number := 0, @prev_post_type_id := NULL) AS vars
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    ORDER BY 
        p.PostTypeId, p.Score DESC, p.CreationDate DESC
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(b.Id) AS TotalBadges,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostUserStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        tp.Tags,
        u.Id AS UserId,
        u.DisplayName,
        us.TotalBounties,
        us.TotalBadges,
        us.TotalScore
    FROM 
        TopPosts tp
    JOIN 
        Users u ON tp.Tags LIKE CONCAT('%<', u.DisplayName, '>%')
    JOIN 
        UserStats us ON u.Id = us.UserId
)
SELECT 
    pus.PostId,
    pus.Title,
    pus.Score,
    pus.ViewCount,
    pus.TotalBounties,
    pus.TotalBadges,
    pus.TotalScore
FROM 
    PostUserStats pus
ORDER BY 
    pus.Score DESC, pus.ViewCount DESC;
