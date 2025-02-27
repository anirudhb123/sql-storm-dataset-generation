WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
), 
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.OwnerDisplayName,
        rp.CreationDate
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 10
)
SELECT 
    t.PostId,
    t.Title,
    t.ViewCount,
    t.Score,
    t.CommentCount,
    t.OwnerDisplayName,
    EXTRACT(EPOCH FROM (NOW() - t.CreationDate)) AS AgeInSeconds,
    (SELECT 
        JSON_AGG(b.Name) 
     FROM 
        Badges b 
     WHERE 
        b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = t.PostId)
    ) AS OwnerBadges
FROM 
    TopPosts t
ORDER BY 
    t.Score DESC, t.ViewCount DESC;
