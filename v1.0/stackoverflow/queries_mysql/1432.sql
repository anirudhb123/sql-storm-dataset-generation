
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(COALESCE(v.Score, 0)) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (
            SELECT 
                PostId,
                SUM(CASE WHEN VoteTypeId = 2 THEN 1 WHEN VoteTypeId = 3 THEN -1 ELSE 0 END) AS Score
            FROM 
                Votes 
            GROUP BY 
                PostId
        ) v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
), PopularTags AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM 
        (
            SELECT 
                SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName
            FROM 
                Posts
            INNER JOIN 
                (SELECT a.N + b.N * 10 AS n
                FROM 
                    (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
                     UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
                     UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                    (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
                     UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
                     UNION ALL SELECT 8 UNION ALL SELECT 9) b
                    ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
            WHERE 
                PostTypeId = 1
        ) AS TagsList
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
)

SELECT 
    ups.DisplayName,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.AverageScore,
    pt.TagName,
    pt.TagCount
FROM 
    UserPostStats ups
CROSS JOIN 
    PopularTags pt
WHERE 
    ups.TotalPosts > 10
ORDER BY 
    ups.AverageScore DESC, pt.TagCount DESC
LIMIT 10 OFFSET 0;
