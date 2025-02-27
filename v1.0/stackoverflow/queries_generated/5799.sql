WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.Score, 
        p.CreationDate, 
        COUNT(c.Id) AS CommentCount, 
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.*, 
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        bh.Count AS BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.Id)
    LEFT JOIN 
        Badges bh ON bh.UserId = u.Id
    WHERE 
        rp.RankScore <= 10 -- Top 10 posts
    GROUP BY 
        rp.Id, u.DisplayName, u.Reputation
)
SELECT 
    tp.Title, 
    tp.Score, 
    tp.CreationDate, 
    tp.CommentCount, 
    tp.VoteCount, 
    tp.OwnerDisplayName, 
    tp.OwnerReputation, 
    COALESCE(SUM(CASE WHEN bh.Class = 1 THEN 1 ELSE 0 END), 0) as GoldBadges,
    COALESCE(SUM(CASE WHEN bh.Class = 2 THEN 1 ELSE 0 END), 0) as SilverBadges,
    COALESCE(SUM(CASE WHEN bh.Class = 3 THEN 1 ELSE 0 END), 0) as BronzeBadges
FROM 
    TopPosts tp
LEFT JOIN 
    Badges bh ON bh.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.Id)
GROUP BY 
    tp.Title, tp.Score, tp.CreationDate, tp.CommentCount, tp.VoteCount, tp.OwnerDisplayName, tp.OwnerReputation
ORDER BY 
    tp.Score DESC;
