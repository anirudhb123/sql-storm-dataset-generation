WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.ViewCount > 100
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.Score, p.ViewCount
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    trp.Title,
    trp.Tags,
    trp.CreationDate,
    trp.Score,
    trp.ViewCount,
    COALESCE(ut.BadgesCount, 0) AS UserBadges,
    COALESCE(ut.Reputation, 0) AS UserReputation,
    pt.Name AS PostType,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount
FROM 
    TopRankedPosts trp
JOIN 
    Users u ON trp.PostId = u.Id
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgesCount,
        SUM(Reputation) AS Reputation 
    FROM 
        Badges 
    GROUP BY 
        UserId
) ut ON u.Id = ut.UserId
JOIN 
    PostTypes pt ON trp.Id = pt.Id
LEFT JOIN 
    PostLinks pl ON trp.PostId = pl.PostId
GROUP BY 
    trp.Title, trp.Tags, trp.CreationDate, trp.Score, trp.ViewCount, ut.BadgesCount, ut.Reputation, pt.Name 
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
