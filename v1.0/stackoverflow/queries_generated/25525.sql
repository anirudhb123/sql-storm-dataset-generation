WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        u.DisplayName AS Author, 
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
), FilteredPosts AS (
    SELECT 
        rp.*, 
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostsTags pt ON rp.PostId = pt.PostId
    LEFT JOIN 
        Tags t ON pt.TagId = t.Id
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.Author, rp.CommentCount
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Author,
    fp.CommentCount,
    fp.Tags
FROM 
    FilteredPosts fp
WHERE 
    fp.PostRank <= 5  -- Top 5 ranked posts per type
ORDER BY 
    fp.CreationDate DESC;
