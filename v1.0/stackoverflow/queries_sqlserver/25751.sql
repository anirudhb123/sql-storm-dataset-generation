
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        Author,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 10
)
SELECT 
    fp.Title,
    fp.Author,
    fp.CommentCount,
    fp.VoteCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
FROM 
    FilteredPosts fp
LEFT JOIN 
    Posts p ON fp.PostId = p.Id
CROSS APPLY 
    STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>') AS tag
LEFT JOIN 
    Tags t ON tag.value = t.TagName
GROUP BY 
    fp.Title, fp.Author, fp.CommentCount, fp.VoteCount
ORDER BY 
    fp.VoteCount DESC;
