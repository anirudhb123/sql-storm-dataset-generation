WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        upvotes = COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0),
        downvotes = COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0),
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2)  -- Include only Questions and Answers
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.upvotes,
        rp.downvotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5  -- Top 5 posts per type
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS TotalUpvotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.PostsCount,
    up.TotalViews,
    up.TotalUpvotes,
    up.TotalDownvotes,
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score
FROM 
    UserStats up
JOIN 
    TopPosts tp ON up.PostsCount > 0
ORDER BY 
    up.TotalViews DESC, tp.Score DESC;
