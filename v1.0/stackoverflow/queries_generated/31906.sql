WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- posts created in the last year
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 -- Top 10 posts per PostTypeId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadges,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS Comments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.CreationDate,
    u.DisplayName,
    u.AvgReputation,
    u.TotalBadges,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(pc.Comments, 'No comments') AS Comments
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.PostId = u.Id -- Assuming user participated in the post creation
LEFT JOIN 
    PostComments pc ON tp.PostId = pc.PostId
WHERE 
    u.AvgReputation >= 500 -- filter users with average reputation of 500 or more
ORDER BY 
    tp.ViewCount DESC;
