
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotedCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotedCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.OwnerUserId
), 
AggregatedTags AS (
    SELECT 
        value AS Tag
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(Tags, '>') 
    WHERE 
        PostTypeId = 1  
), 
MostUsedTags AS (
    SELECT 
        Tag,
        COUNT(*) AS UsageCount
    FROM 
        AggregatedTags
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    rp.UpvotedCount,
    rp.DownvotedCount,
    mt.Tag AS MostUsedTag
FROM 
    RankedPosts rp
JOIN 
    MostUsedTags mt ON rp.Tags LIKE '%' + mt.Tag + '%'
WHERE 
    rp.UserRank <= 5  
ORDER BY 
    rp.CreationDate DESC;
