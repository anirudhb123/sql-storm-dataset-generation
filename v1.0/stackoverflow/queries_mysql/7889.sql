
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagsArr
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tag_name
         FROM 
             (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
              SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
              SELECT 9 UNION ALL SELECT 10) n
         WHERE 
             CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM tag_name)
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
        @row_num := @row_num + 1 AS Rank
    FROM 
        RankedPosts, (SELECT @row_num := 0) AS rn
    ORDER BY 
        Score DESC, CreationDate DESC
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
