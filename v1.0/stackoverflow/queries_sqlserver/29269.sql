
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(DISTINCT v.Id) DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS APPLY 
        (SELECT VALUE AS TagName FROM STRING_SPLIT(p.Tags, '<>')) AS tag
    LEFT JOIN 
        Tags t ON t.TagName = tag.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        CreationDate, 
        Author, 
        CommentCount, 
        VoteCount, 
        Tags
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
)
SELECT 
    fp.Author,
    fp.Title,
    fp.CreationDate,
    fp.CommentCount,
    fp.VoteCount,
    fp.Tags,
    LEN(fp.Body) AS BodyLength, 
    LEFT(fp.Body, 100) AS BodyExcerpt
FROM 
    FilteredPosts fp
ORDER BY 
    fp.VoteCount DESC, 
    fp.CreationDate DESC;
