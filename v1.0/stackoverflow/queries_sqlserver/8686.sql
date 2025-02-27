
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        STRING_AGG(t.TagName, ',') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    OUTER APPLY (
        SELECT 
            value AS TagName 
        FROM 
            STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')
    ) AS tag
    LEFT JOIN 
        Tags t ON tag.TagName = t.TagName
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56') 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId, Title, OwnerDisplayName, ViewCount, Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.Tags,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS UpVoteCount
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC;
