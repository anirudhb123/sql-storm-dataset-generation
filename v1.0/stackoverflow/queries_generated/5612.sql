WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.Score DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RankDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 YEAR'
        AND p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score,
        CreationDate,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 5 OR RankDate <= 5
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,  
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
)
SELECT 
    t.Title,
    t.ViewCount,
    t.Score,
    t.CommentCount,
    u.DisplayName,
    u.TotalPosts,
    u.TotalComments,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    u.Upvotes,
    u.Downvotes
FROM 
    TopPosts t
JOIN 
    UserStats u ON t.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.UserId)
ORDER BY 
    t.Score DESC, t.ViewCount DESC;
