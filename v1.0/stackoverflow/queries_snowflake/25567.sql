
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id 
    WHERE 
        p.PostTypeId = 1 
),
TagStatistics AS (
    SELECT 
        TRIM(value) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts,
        LATERAL FLATTEN(input => SPLIT(SUBSTR(Tags, 2, LENGTH(Tags) - 2), '><')) 
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(p.Id) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalScore DESC
    LIMIT 10
)
SELECT 
    rp.OwnerDisplayName,
    rp.Title,
    rp.CreationDate,
    ts.Tag,
    ts.PostCount,
    tu.TotalScore,
    tu.QuestionCount
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON ts.Tag IN (SELECT TRIM(value) FROM LATERAL FLATTEN(input => SPLIT(SUBSTR(rp.Tags, 2, LENGTH(rp.Tags) - 2), '><')))
JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE 
    rp.PostRank = 1 
ORDER BY 
    ts.PostCount DESC;
