WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tagname ON true
    JOIN 
        Tags t ON t.TagName = tagname
    WHERE 
        p.PostTypeId = 1 -- Questions
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.TotalBounty,
    rp.CommentCount,
    pt.TagsList
FROM 
    RankedPosts rp
LEFT JOIN 
    PostTags pt ON rp.PostId = pt.PostId
WHERE 
    rp.Rank = 1  -- Only getting the latest entry for each post
ORDER BY 
    rp.ViewCount DESC,
    rp.TotalBounty DESC
LIMIT 10;
