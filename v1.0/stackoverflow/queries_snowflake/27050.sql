
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
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTR(p.Tags, 2, LENGTH(p.Tags)-2), '><')) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag.VALUE
    WHERE 
        p.CreationDate > DATEADD(YEAR, -1, '2024-10-01 12:34:56'::timestamp)
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
    ARRAY_TO_STRING(rp.Tags, ', ') AS Tags
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC;
