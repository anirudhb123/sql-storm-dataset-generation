
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        STRING_AGG(DISTINCT t.TagName, ',') AS Tags,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    CROSS APPLY 
        (SELECT value AS tag_name FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')) AS tag_name 
    JOIN 
        Tags t ON t.TagName = tag_name.value
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
FilteredPosts AS (
    SELECT 
        rp.*,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId = 2) AS Upvotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId = 3) AS Downvotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.AnswerCount > 0
)

SELECT 
    fp.Id,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.AnswerCount,
    fp.Tags,
    fp.Upvotes,
    fp.Downvotes,
    ROUND(COALESCE(CAST(fp.Upvotes AS FLOAT) / NULLIF(fp.Upvotes + fp.Downvotes, 0), 0), 2) AS UpvoteRatio
FROM 
    FilteredPosts fp
WHERE 
    fp.PostRank <= 10 
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;
