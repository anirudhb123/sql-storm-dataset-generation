
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        u.DisplayName AS Owner, 
        u.Reputation AS OwnerReputation, 
        p.CreationDate,
        p.Score, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
PopularTags AS (
    SELECT 
        TRIM(value) AS TagName
    FROM 
        Posts, 
        LATERAL FLATTEN(INPUT => SPLIT(Tags, ','))
    WHERE 
        PostTypeId = 1
),
TopTags AS (
    SELECT 
        TagName, 
        COUNT(*) AS TagCount
    FROM 
        PopularTags
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostWithTopTags AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Owner, 
        rp.OwnerReputation, 
        rp.CreationDate, 
        rt.TagName
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    JOIN 
        TopTags rt ON rt.TagName IN (SELECT TRIM(value) FROM LATERAL FLATTEN(INPUT => SPLIT(p.Tags, ',')))
)
SELECT 
    pwap.*,
    COUNT(c.Id) AS CommentCount,
    AVG(v.BountyAmount) AS AvgBounty 
FROM 
    PostWithTopTags pwap
LEFT JOIN 
    Comments c ON pwap.PostId = c.PostId
LEFT JOIN 
    Votes v ON pwap.PostId = v.PostId AND v.VoteTypeId = 8 
GROUP BY 
    pwap.PostId, pwap.Title, pwap.Owner, pwap.OwnerReputation, pwap.CreationDate, pwap.TagName
ORDER BY 
    pwap.CreationDate DESC;
