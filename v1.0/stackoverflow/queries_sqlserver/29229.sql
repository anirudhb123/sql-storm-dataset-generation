
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoterCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.CreationDate >= CAST(DATEADD(DAY, -30, '2024-10-01') AS DATE)
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount
),
PopularTags AS (
    SELECT 
        LTRIM(RTRIM(value)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, '>') 
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        LTRIM(RTRIM(value))
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.ViewCount,
    rp.CommentCount,
    rp.UniqueVoterCount,
    pt.TagName
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON pt.TagName IN (SELECT value FROM STRING_SPLIT(rp.Tags, '>')) 
WHERE 
    rp.Rank = 1 
ORDER BY 
    rp.ViewCount DESC, 
    rp.CommentCount DESC;
