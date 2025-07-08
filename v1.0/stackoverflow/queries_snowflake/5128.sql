
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
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '90 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName, pt.Name
), PopularTags AS (
    SELECT 
        VALUE AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts,
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) 
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.PostTypeName,
    rp.VoteCount,
    (SELECT LISTAGG(TagName, ', ') WITHIN GROUP (ORDER BY TagName) FROM PopularTags) AS PopularTags,
    rp.Rank
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate DESC;
