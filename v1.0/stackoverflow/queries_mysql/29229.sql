
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
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY) 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount
),
PopularTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    JOIN 
        (SELECT a.N + b.N * 10 + 1 n FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
             UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
             UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b 
         ) n 
    WHERE 
        n.n <= 1 + LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '>', ''))
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
    PopularTags pt ON FIND_IN_SET(pt.TagName, rp.Tags) > 0
WHERE 
    rp.Rank = 1 
ORDER BY 
    rp.ViewCount DESC, 
    rp.CommentCount DESC;
