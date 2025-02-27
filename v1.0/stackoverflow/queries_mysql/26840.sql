
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TagSplit AS (
    SELECT 
        rp.PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', n.n), '>', -1) AS Tag, 
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Score
    FROM 
        RankedPosts rp
    JOIN 
        (SELECT a.N + b.N * 10 + 1 n FROM 
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
             UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a, 
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
             UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b
        ) n ON CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, '><', '')) >= n.n - 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        ts.Tag,
        COUNT(ts.PostId) AS TagCount
    FROM 
        TagSplit ts
    GROUP BY 
        ts.Tag
    HAVING 
        COUNT(ts.PostId) > 10 
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.QuestionCount,
        us.TotalViews,
        us.AvgScore,
        ROW_NUMBER() OVER (ORDER BY us.TotalViews DESC) AS ViewRank
    FROM 
        UserStats us
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.QuestionCount,
    tu.TotalViews,
    tu.AvgScore,
    pt.Tag AS PopularTag,
    pt.TagCount
FROM 
    TopUsers tu
JOIN 
    PopularTags pt ON tu.QuestionCount > 5 
ORDER BY 
    tu.QuestionCount DESC, 
    pt.TagCount DESC;
