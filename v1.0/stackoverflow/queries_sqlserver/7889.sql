
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        STRING_AGG(DISTINCT t.TagName, ',') AS TagsArr
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN 
        (SELECT DISTINCT value AS tag_name FROM STRING_SPLIT(p.Tags, '><')) AS tag_name ON 1 = 1
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM tag_name.tag_name)
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
AggregatedPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        CreationDate,
        OwnerDisplayName,
        VoteCount,
        TagsArr,
        ROW_NUMBER() OVER (ORDER BY Score DESC, CreationDate DESC) AS Rank
    FROM 
        RankedPosts
)
SELECT 
    PostId,
    Title,
    Score,
    CreationDate,
    OwnerDisplayName,
    VoteCount,
    TagsArr
FROM 
    AggregatedPosts
WHERE 
    Rank <= 10  
ORDER BY 
    Score DESC, CreationDate DESC;
