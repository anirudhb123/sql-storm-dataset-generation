WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Upvotes only
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -6, GETDATE()) -- Posts from the last 6 months
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.*,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        u.Location,
        b.Name AS BadgeName
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Date >= DATEADD(YEAR, -1, GETDATE()) -- Badges in the last year
    WHERE 
        rp.PostRank <= 10 -- Top 10 posts per type
)
SELECT 
    PostId,
    Title,
    Score,
    ViewCount,
    CommentCount,
    VoteCount,
    CreationDate,
    OwnerDisplayName,
    Reputation,
    Location,
    BadgeName
FROM 
    TopPosts
ORDER BY 
    CreationDate DESC, Score DESC;
