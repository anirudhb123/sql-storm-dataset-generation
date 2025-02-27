
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        (LEN(REPLACE(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><', '')) + 1 - LEN(REPLACE(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>', '')))/2) AS TagCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND  
        p.CreationDate > CAST(DATEADD(YEAR, -1, '2024-10-01') AS DATE)  
),
TopUsers AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostId) AS QuestionCount,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5  
    GROUP BY 
        OwnerDisplayName
),
UserBadges AS (
    SELECT 
        u.DisplayName AS OwnerDisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
)
SELECT 
    tu.OwnerDisplayName,
    tu.QuestionCount,
    tu.TotalScore,
    ub.BadgeCount
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.OwnerDisplayName = ub.OwnerDisplayName
ORDER BY 
    tu.TotalScore DESC,
    tu.QuestionCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
