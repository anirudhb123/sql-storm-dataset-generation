
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        pt.Name AS PostTypeName,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(DAY, -90, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName, pt.Name
), PopularTags AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        value
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.PostTypeName,
    rp.VoteCount,
    (SELECT STRING_AGG(TagName, ', ') FROM PopularTags) AS PopularTags,
    rp.Rank
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate DESC;
