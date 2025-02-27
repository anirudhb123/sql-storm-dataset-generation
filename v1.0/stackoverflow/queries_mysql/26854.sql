
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
        LEFT JOIN Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, p.ViewCount
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT a.Id) AS AnswersGiven,
        SUM(IFNULL(a.Score, 0)) AS TotalAnswerScore,
        SUM(IFNULL(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
        LEFT JOIN Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2 
        LEFT JOIN Votes v ON a.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName
),

PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    INNER JOIN (
        SELECT 
            1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
            UNION ALL SELECT 9 UNION ALL SELECT 10
    ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)

SELECT 
    p.Title AS QuestionTitle,
    p.CreationDate AS QuestionDate,
    u.DisplayName AS Owner,
    u.QuestionsAsked,
    u.AnswersGiven,
    u.TotalAnswerScore,
    u.TotalBounties,
    (SELECT GROUP_CONCAT(tag.TagName SEPARATOR ', ') 
     FROM PopularTags tag) AS TopTags
FROM 
    RankedPosts p
JOIN 
    UserActivity u ON p.OwnerUserId = u.UserId
WHERE 
    p.rn = 1 
ORDER BY 
    p.ViewCount DESC
LIMIT 20;
