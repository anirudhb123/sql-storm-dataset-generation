WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoterCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Counting only UpVotes
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days' -- Posts created in the last 30 days
    GROUP BY 
        p.Id
),
PopularTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(p.Tags, '>'))) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.ViewCount,
    rp.CommentCount,
    rp.UniqueVoterCount,
    pt.TagName
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON pt.TagName = ANY(string_to_array(rp.Tags, '>')) 
WHERE 
    rp.Rank = 1 -- Focusing on the most viewed post per ID
ORDER BY 
    rp.ViewCount DESC, 
    rp.CommentCount DESC;
