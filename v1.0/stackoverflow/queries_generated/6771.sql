WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        CommentCount,
        ViewCount,
        Author
    FROM 
        RankedPosts
    WHERE 
        UserPostRank = 1
),
BadgedUsers AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.ViewCount,
    tp.Author,
    bu.BadgeCount
FROM 
    TopPosts tp
JOIN 
    BadgedUsers bu ON tp.Author = bu.UserId
WHERE 
    bu.BadgeCount > 0
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
LIMIT 10;
