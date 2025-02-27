WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 10
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.VoteCount,
    pt.Name AS PostTypeName,
    COUNT(b.Id) AS BadgeCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON tp.PostTypeId = pt.Id
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN 
    unnest(string_to_array(substring((SELECT Tags FROM Posts WHERE Id = tp.PostId), 2, length((SELECT Tags FROM Posts WHERE Id = tp.PostId))-2), '><')) AS t(TagName)
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.ViewCount, tp.Score, tp.OwnerDisplayName, pt.Name
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC;
