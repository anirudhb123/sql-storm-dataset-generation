
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        p.OwnerUserId,
        p.Tags
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PopularTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS Tag
    FROM 
        Posts 
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
),
TagStatistics AS (
    SELECT 
        t.Tag AS TagName,
        COUNT(*) AS TagCount
    FROM 
        PopularTags t
    GROUP BY 
        t.Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    up.UserId,
    up.Reputation,
    up.TotalBounty,
    rp.Title,
    rp.Score,
    rp.AnswerCount,
    rp.ViewCount,
    tt.TagName
FROM 
    UserReputation up
JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId
LEFT JOIN 
    TagStatistics tt ON tt.TagName = rp.Tags
WHERE 
    up.Reputation > 1000
    AND (rp.AnswerCount > 5 OR rp.ViewCount > 100)
ORDER BY 
    up.Reputation DESC, rp.Score DESC
LIMIT 50;
