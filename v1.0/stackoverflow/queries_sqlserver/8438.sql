
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount, p.Tags
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    (tp.UpVoteCount - tp.DownVoteCount) AS NetVoteCount,
    STRING_AGG(t.TagName, ', ') AS RelatedTags
FROM 
    TopPosts tp
LEFT JOIN 
    Tags t ON t.TagName IN (SELECT value FROM STRING_SPLIT(tp.Tags, ', '))
GROUP BY 
    tp.PostId, tp.OwnerDisplayName, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.CommentCount, tp.UpVoteCount, tp.DownVoteCount
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
