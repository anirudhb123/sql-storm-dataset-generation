WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN
        Tags t ON POSITION(t.TagName IN p.Tags) > 0
    WHERE
        p.PostTypeId = 1 -- Only Questions
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Author,
        CreationDate,
        Score,
        Tags
    FROM
        RankedPosts
    WHERE
        Rank <= 5
),
PostComments AS (
    SELECT 
        pc.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    JOIN 
        Posts pc ON c.PostId = pc.Id
    GROUP BY 
        pc.PostId
),
PostBadges AS (
    SELECT
        b.UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tp.Title,
    tp.Author,
    tp.CreationDate,
    tp.Score,
    tp.Tags,
    pc.CommentCount,
    b.BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostComments pc ON tp.PostId = pc.PostId
LEFT JOIN 
    Users u ON tp.Author = u.DisplayName
LEFT JOIN 
    PostBadges b ON u.Id = b.UserId
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate ASC;
