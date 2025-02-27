
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT p.Id, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1) AS tagName
         FROM Posts p
         JOIN (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
               UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
         ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= n.n - 1) AS tagName ON true
    LEFT JOIN 
        Tags t ON t.TagName = tagName.tagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId, u.DisplayName
),
TopUsers AS (
    SELECT 
        OwnerUserId, 
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews
    FROM 
        RankedPosts 
    WHERE 
        PostRank <= 5 
    GROUP BY 
        OwnerUserId
    ORDER BY 
        TotalScore DESC
    LIMIT 10
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    tu.TotalViews,
    GROUP_CONCAT(rp.Title) AS TopPostTitles,
    GROUP_CONCAT(rp.Score) AS TopPostScores
FROM 
    TopUsers tu
JOIN 
    Users u ON u.Id = tu.OwnerUserId
JOIN 
    RankedPosts rp ON rp.OwnerUserId = u.Id
GROUP BY 
    u.Id, u.DisplayName, tu.PostCount, tu.TotalScore, tu.TotalViews
ORDER BY 
    tu.TotalScore DESC;
