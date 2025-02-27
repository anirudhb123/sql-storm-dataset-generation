
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.Tags
),

TagStats AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS Tag
    WHERE 
        PostTypeId = 1
    GROUP BY 
        value
    ORDER BY 
        PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.CommentCount,
    ts.TagName,
    ts.PostCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotes
FROM 
    RankedPosts rp
JOIN 
    TagStats ts ON ts.TagName IN (SELECT value FROM STRING_SPLIT(SUBSTRING(rp.Tags, 2, LEN(rp.Tags) - 2), '><'))
WHERE 
    rp.Rank = 1 
ORDER BY 
    rp.CreationDate DESC;
