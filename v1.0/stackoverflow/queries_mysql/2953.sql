
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR 
        AND p.Score > 0
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT @row := @row + 1 AS n FROM 
            (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t1,
            (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t2,
            (SELECT @row := 0) t0) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    tu.TotalViews,
    RANK() OVER (ORDER BY tu.TotalScore DESC) AS UserRank,
    pt.TagName,
    pt.TagCount
FROM 
    TopUsers tu
LEFT JOIN 
    PopularTags pt ON pt.TagName IN (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1)
        FROM 
            Posts
        JOIN 
            (SELECT @row := @row + 1 AS n FROM 
                (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t1,
                (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t2,
                (SELECT @row := 0) t0) numbers 
        WHERE 
            OwnerUserId = tu.UserId
    )
WHERE 
    EXISTS (
        SELECT 
            1 
        FROM 
            Votes v 
        WHERE 
            v.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = tu.UserId) 
            AND v.VoteTypeId = 2
    )
ORDER BY 
    tu.TotalScore DESC, tu.PostCount DESC;
