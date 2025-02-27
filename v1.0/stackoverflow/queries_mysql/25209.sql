
WITH RankedPostTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        t.TagName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY t.Count DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag
         FROM Posts p
         JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
                      SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
                      SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) 
         - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag ON tag IS NOT NULL
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1 
),
TopTags AS (
    SELECT 
        PostId,
        GROUP_CONCAT(TagName ORDER BY TagRank) AS TagsList
    FROM 
        RankedPostTags
    WHERE 
        TagRank <= 3 
    GROUP BY 
        PostId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalAnswers,
    ups.AcceptedAnswers,
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    t.TagsList
FROM 
    UserPostStats ups
JOIN 
    Posts p ON p.OwnerUserId = ups.UserId
JOIN 
    TopTags t ON t.PostId = p.Id
WHERE 
    ups.TotalPosts > 0
ORDER BY 
    ups.TotalPosts DESC, p.CreationDate DESC
LIMIT 10;
