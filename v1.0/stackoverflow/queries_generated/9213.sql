WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= now() - interval '1 year' 
        AND p.Score > 0
),
ModeratedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Author,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        t.TagName
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        rp.Rank <= 10
    ORDER BY 
        rp.Score DESC
)
SELECT 
    mp.Title,
    mp.Author,
    mp.CreationDate,
    mp.Score,
    mp.ViewCount,
    STRING_AGG(mt.Name, ', ') AS Tags
FROM 
    ModeratedPosts mp
LEFT JOIN 
    PostLinks pl ON mp.PostId = pl.PostId
LEFT JOIN 
    LinkTypes lt ON pl.LinkTypeId = lt.Id
JOIN 
    Tags mt ON mt.Id = pl.RelatedPostId
GROUP BY 
    mp.PostId, mp.Title, mp.Author, mp.CreationDate, mp.Score, mp.ViewCount
ORDER BY 
    mp.Score DESC, mp.CreationDate DESC;
