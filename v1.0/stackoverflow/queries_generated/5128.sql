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
        p.CreationDate >= NOW() - INTERVAL '90 days'
    GROUP BY 
        p.Id, u.DisplayName, pt.Name
), PopularTags AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
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
    (SELECT STRING_AGG(TagName, ', ') FROM PopularTags) AS PopularTags,
    rp.Rank
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5 -- Top 5 posts per owner
ORDER BY 
    rp.ViewCount DESC, rp.CreationDate DESC;
