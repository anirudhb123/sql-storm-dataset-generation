
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(v.Id) DESC, COUNT(c.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR') 
        AND p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Body, u.DisplayName
),
FrequentTags AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p,
        TABLE(FLATTEN(INPUT => SPLIT(TRIM(BOTH '<>' FROM p.Tags), '>'))) AS tag
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR') 
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 10
),
PostAggregate AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount,
        COALESCE(ft.TagCount, 0) AS FrequentTagCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        FrequentTags ft ON POSITION(ft.TagName IN rp.Title) > 0
    WHERE 
        rp.Rank <= 10
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.OwnerDisplayName,
    pa.CommentCount,
    pa.VoteCount,
    pa.FrequentTagCount
FROM 
    PostAggregate pa
ORDER BY 
    pa.VoteCount DESC, pa.CommentCount DESC
LIMIT 20;
