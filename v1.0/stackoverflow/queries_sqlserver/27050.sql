
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS Author,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>') AS tag ON 1=1
    LEFT JOIN 
        Tags t ON t.TagName = tag.value
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, u.Reputation, pt.Name
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.Author,
    rp.Reputation,
    rp.Rank,
    rp.Tags
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC;
