
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.Id ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP('2024-10-01 12:34:56') - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.Tags
),
TagUsage AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    JOIN (
        SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
        UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP('2024-10-01 12:34:56') - INTERVAL 6 MONTH
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
UserParticipation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersProvided,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate >= TIMESTAMP('2024-10-01 12:34:56') - INTERVAL 1 YEAR
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.Title,
    rp.ViewCount,
    rp.Score,
    tu.TagName,
    up.DisplayName,
    up.PostsCreated,
    up.AnswersProvided,
    up.AcceptedAnswers
FROM 
    RankedPosts rp
LEFT JOIN 
    TagUsage tu ON rp.Tags LIKE CONCAT('%', tu.TagName, '%')
LEFT JOIN 
    UserParticipation up ON rp.PostId = (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.OwnerUserId = up.UserId 
        ORDER BY p.CreationDate ASC 
        LIMIT 1
    )
WHERE 
    rp.RankByViews <= 5
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC;
