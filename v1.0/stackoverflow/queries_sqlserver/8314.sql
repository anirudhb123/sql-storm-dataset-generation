
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
PopularTags AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(p.Tags, '<>') 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        TRIM(value)
    ORDER BY 
        PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    pt.TagName
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.Rank <= 10
WHERE 
    rp.Score > 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
