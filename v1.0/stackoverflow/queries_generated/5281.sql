WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerDisplayName,
        p.Score,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS TotalComments,
        (SELECT COUNT(DISTINCT UserId) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS TotalUpvotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
        AND p.PostTypeId IN (1, 2) -- Considering only Questions and Answers
), 
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score,
        rp.TotalComments,
        rp.TotalUpvotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
), 
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.OwnerUserId = u.Id THEN 1 ELSE 0 END) AS PostsCreated,
        SUM(CASE WHEN c.UserId = u.Id THEN 1 ELSE 0 END) AS CommentsMade,
        SUM(CASE WHEN b.UserId = u.Id THEN 1 ELSE 0 END) AS BadgesEarned
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
) 
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.Score AS PostScore,
    tp.TotalComments,
    tp.TotalUpvotes,
    us.UserId,
    us.DisplayName AS Author,
    us.PostsCreated,
    us.CommentsMade,
    us.BadgesEarned
FROM 
    TopPosts tp
JOIN 
    UserStats us ON tp.OwnerDisplayName = us.DisplayName
ORDER BY 
    tp.Score DESC, 
    us.BadgesEarned DESC;
