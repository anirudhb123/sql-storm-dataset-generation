
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(t.TagName) AS TagCount,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName
         FROM Posts p
         JOIN (SELECT 1+n.n AS n FROM (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) n) n
         WHERE n.n <= 1 + (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', ''))) 
        ) AS t ON TRUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(IFNULL(p.Score, 0)) AS TotalScore,
        SUM(IFNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(IFNULL(p.AnswerCount, 0)) AS TotalAnswers
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        pt.TagCount,
        ups.TotalScore,
        ups.TotalViews,
        ups.TotalAnswers,
        RANK() OVER (ORDER BY ups.TotalScore DESC, pt.TagCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTagCounts pt ON p.Id = pt.PostId
    JOIN 
        UserPostStats ups ON p.OwnerUserId = ups.UserId
    WHERE 
        p.PostTypeId = 1 
        AND pt.TagCount >= 2 
)
SELECT 
    rp.Rank,
    rp.Title,
    rp.TagCount,
    rp.TotalScore,
    rp.TotalViews,
    rp.TotalAnswers
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.Rank;
