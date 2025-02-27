
WITH PostTagCount AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p 
    INNER JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
            ) numbers 
        WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS t ON TRUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        COUNT(DISTINCT p.Id) AS QuestionsAnswered
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId IN (2, 1) 
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(ph.Comment, 'No comments') AS RecentComment,
        @rank := IF(@prevPostId = p.Id, @rank + 1, 1) AS CommentRank,
        @prevPostId := p.Id
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    CROSS JOIN (SELECT @rank := 0, @prevPostId := NULL) r
    WHERE 
        p.PostTypeId IN (1, 2)
)
SELECT 
    pt.PostId,
    ra.Title,
    pt.TagCount,
    pt.Tags,
    pu.DisplayName AS ActiveUser,
    pu.TotalViews,
    ra.RecentComment
FROM 
    PostTagCount pt
JOIN 
    RecentPostActivity ra ON pt.PostId = ra.PostId
JOIN 
    PopularUsers pu ON pu.UserId = ra.PostId
WHERE 
    ra.CommentRank = 1
ORDER BY 
    pt.TagCount DESC, pu.TotalViews DESC;
