
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate > NOW() - INTERVAL 1 YEAR AND 
        p.ViewCount > 1000
),
TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', numbers.n), '>', -1) AS Tag,
        COUNT(*) AS PostCount,
        AVG(TIMESTAMPDIFF(SECOND, CreationDate, NOW())) AS AvgAgeInSeconds
    FROM 
        RankedPosts
    JOIN 
    (
        SELECT 
            1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '>', '')) >= numbers.n - 1
    GROUP BY 
        Tag
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rs.PostId,
    rs.Title,
    rs.Body,
    ts.Tag,
    ts.PostCount,
    ts.AvgAgeInSeconds,
    ur.DisplayName AS UserName,
    ur.TotalBounty,
    ur.PostsCount
FROM 
    RankedPosts rs
JOIN 
    TagStatistics ts ON FIND_IN_SET(ts.Tag, REPLACE(rs.Tags, '>', ',')) > 0
JOIN 
    UserReputation ur ON ur.UserId = rs.OwnerUserId
WHERE 
    rs.TagRank = 1
ORDER BY 
    ts.PostCount DESC, 
    ur.TotalBounty DESC
LIMIT 10;
