
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.PostTypeId = 1 
        AND p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01') AS DATE) 
    GROUP BY
        p.Id, p.Title, p.Tags, p.CreationDate, u.DisplayName
    HAVING
        COUNT(c.Id) > 5 
),
TopPosts AS (
    SELECT
        PostId,
        Title,
        Tags,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        VoteCount
    FROM
        RankedPosts
    WHERE
        Rank = 1
)
SELECT
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.CommentCount,
    tp.VoteCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS RelatedTags,
    CASE 
        WHEN tp.VoteCount > 10 THEN 'Highly Voted'
        WHEN tp.VoteCount BETWEEN 5 AND 10 THEN 'Moderately Voted'
        ELSE 'Less Voted' 
    END AS VoteCategory
FROM
    TopPosts tp
LEFT JOIN
    (SELECT 
         Id, 
         value AS TagName
     FROM 
         Posts
     CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')) AS Tag) t ON t.Id = tp.PostId
GROUP BY
    tp.PostId, tp.Title, tp.OwnerDisplayName, tp.CreationDate, tp.CommentCount, tp.VoteCount
ORDER BY
    tp.VoteCount DESC, tp.CommentCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
