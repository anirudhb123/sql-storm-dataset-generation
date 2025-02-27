WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Created in the last year
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5 -- Top 5 most recent questions per user
),
TagsExploded AS (
    SELECT 
        tp.PostId,
        unnest(string_to_array(tp.Tags, '><')) AS Tag
    FROM 
        TopPosts tp
),
TagCount AS (
    SELECT 
        Tag,
        COUNT(*) AS PostCount
    FROM 
        TagsExploded
    GROUP BY 
        Tag
)
SELECT 
    t.Tag,
    t.PostCount,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId IN (SELECT PostId FROM TopPosts)) AS TotalComments
FROM 
    TagCount t
LEFT JOIN 
    Posts p ON p.Tags LIKE '%' || t.Tag || '%'
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Only Bounty Start and Bounty Close votes
GROUP BY 
    t.Tag, t.PostCount
ORDER BY 
    t.PostCount DESC;
