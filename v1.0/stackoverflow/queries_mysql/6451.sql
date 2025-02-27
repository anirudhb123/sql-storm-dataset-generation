
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
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
PopularTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1)) AS TagName
    FROM 
        Posts 
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
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
        TopTags rt ON FIND_IN_SET(rt.TagName, p.Tags) > 0
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
