WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name, u.DisplayName
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
        SUM(v.Id IS NOT NULL) AS TotalVotes,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate < NOW() - INTERVAL '2 years'
    GROUP BY 
        u.Id
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
