
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) 
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName, 
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
)
SELECT 
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    ps.CommentCount,
    ps.TotalBountyAmount,
    pt.TagName AS PopularTag
FROM 
    RankedPosts rp
JOIN 
    PostStatistics ps ON rp.PostId = ps.PostId
JOIN 
    PopularTags pt ON FIND_IN_SET(pt.TagName, REPLACE(rp.Tags, '><', ',')) > 0
WHERE 
    rp.OwnerPostRank = 1 
ORDER BY 
    rp.Score DESC, ps.CommentCount DESC;
