WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.Owner,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1 -- Grab top record for each post
    ORDER BY 
        rp.Score DESC
    LIMIT 10
)
SELECT 
    tp.Title,
    tp.Score,
    tp.Owner,
    tp.CommentCount,
    COALESCE(JSON_AGG(t.TagName), '[]') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    LATERAL (
        SELECT 
            t.TagName
        FROM 
            Tags t
        WHERE 
            t.Id IN (
                SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[]))
                FROM Posts p
                WHERE p.Id = tp.Id
            )
    ) AS t ON true
GROUP BY 
    tp.Title, tp.Score, tp.Owner, tp.CommentCount
ORDER BY 
    tp.Score DESC;
