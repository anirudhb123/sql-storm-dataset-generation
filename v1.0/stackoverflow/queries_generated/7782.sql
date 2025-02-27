WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.ViewCount DESC) AS RankInType,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        p.Id, pt.Name, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.VoteCount,
        rp.BadgeCount,
        pt.Name AS PostType
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = rp.PostId)
    WHERE 
        rp.RankInType <= 10
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    p.VoteCount,
    p.BadgeCount,
    p.PostType,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    TopPosts p
LEFT JOIN 
    PostsTags pt ON p.PostId = pt.PostId
LEFT JOIN 
    Tags t ON pt.TagId = t.Id
GROUP BY 
    p.PostId, p.Title, p.CreationDate, p.Score, p.ViewCount, p.CommentCount, p.VoteCount, p.BadgeCount, p.PostType
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
