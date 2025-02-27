
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS UpvoteCount,
        STRING_AGG(t.TagName, ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    LEFT JOIN 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags)-2), '><') AS tag ON 1=1
    LEFT JOIN 
        Tags t ON t.TagName = tag.value
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, p.Score
),
BenchmarkResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.TagList,
        ROW_NUMBER() OVER (ORDER BY rp.Score DESC, rp.CommentCount DESC) AS Rank
    FROM 
        RankedPosts rp
)
SELECT 
    br.Rank,
    br.PostId,
    br.Title,
    br.OwnerDisplayName,
    br.CreationDate,
    br.Score,
    br.CommentCount,
    br.UpvoteCount,
    br.TagList
FROM 
    BenchmarkResults br
WHERE 
    br.Score > 10  
ORDER BY 
    br.Rank
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
