
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, p.Tags, p.ViewCount, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Body,
        Tags,
        ViewCount,
        Score,
        OwnerDisplayName,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Body,
    p.Tags,
    p.ViewCount,
    p.Score,
    p.OwnerDisplayName,
    p.CommentCount,
    LISTAGG(DISTINCT t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS AssociatedTags,
    (
        SELECT 
            COUNT(*) 
        FROM 
            Votes v 
        WHERE 
            v.PostId = p.PostId 
            AND v.VoteTypeId = 2
    ) AS UpVotes,
    (
        SELECT 
            COUNT(*) 
        FROM 
            Votes v 
        WHERE 
            v.PostId = p.PostId 
            AND v.VoteTypeId = 3
    ) AS DownVotes
FROM 
    TopPosts p
LEFT JOIN 
    LATERAL FLATTEN(input => SPLIT(p.Tags, '><')) AS tag ON TRUE
JOIN 
    Tags t ON t.TagName = tag.VALUE
GROUP BY 
    p.PostId, p.Title, p.CreationDate, p.Body, p.Tags, p.ViewCount, p.Score, p.OwnerDisplayName, p.CommentCount
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
