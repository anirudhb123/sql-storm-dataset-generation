
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
        p.CreationDate >= DATEADD(DAY, -30, '2024-10-01') 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount
),
PopularTags AS (
    SELECT 
        TRIM(UNNEST(SPLIT(p.Tags, '>'))) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
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
    PopularTags pt ON pt.TagName IN (SELECT TRIM(value) FROM TABLE(SPLIT_TO_TABLE(rp.Tags, '>'))) 
WHERE 
    rp.Rank = 1 
ORDER BY 
    rp.ViewCount DESC, 
    rp.CommentCount DESC;
