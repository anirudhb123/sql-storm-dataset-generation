
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
        AND p.Score > 0  
),
TagOccurrence AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') 
    GROUP BY 
        value
    ORDER BY 
        TagCount DESC
),
PopularTags AS (
    SELECT 
        Tag,
        TagCount
    FROM 
        TagOccurrence
    WHERE 
        TagCount > 10  
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON c.PostId = rp.PostId
    LEFT JOIN 
        PostTypes pt ON pt.Id = (SELECT p.PostTypeId FROM Posts p WHERE p.Id = rp.PostId)
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    COALESCE(pt.TagCount, 0) AS PopularTagCount,
    ps.PostTypes
FROM 
    PostStats ps
LEFT JOIN 
    PopularTags pt ON ps.Title LIKE '%' + pt.Tag + '%'  
WHERE 
    ps.CommentCount > 5  
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
