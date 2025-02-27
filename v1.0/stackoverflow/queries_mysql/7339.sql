
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        @row_num := IF(@prev_pt = pt.Name, @row_num + 1, 1) AS Rank,
        @prev_pt := pt.Name,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId,
        (SELECT @row_num := 0, @prev_pt := '') AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName, pt.Name
),
TopPosts AS (
    SELECT 
        r.Id,
        r.Title,
        r.CreationDate,
        r.ViewCount,
        r.OwnerDisplayName,
        r.Rank,
        r.CommentCount
    FROM 
        RankedPosts r
    WHERE 
        r.Rank <= 5
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate < NOW() - INTERVAL 2 YEAR
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.CommentCount,
    ue.DisplayName AS EngagedUser,
    ue.TotalVotes,
    ue.GoldBadges,
    ue.SilverBadges,
    ue.BronzeBadges
FROM 
    TopPosts tp
JOIN 
    UserEngagement ue ON tp.ViewCount > 5000 AND ue.TotalVotes > 10
ORDER BY 
    tp.ViewCount DESC, ue.TotalVotes DESC;
