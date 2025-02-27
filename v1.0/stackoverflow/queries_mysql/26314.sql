
WITH TagsCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        t.TagName,
        COUNT(t.TagName) AS TagCount
    FROM 
        Posts p
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag
         FROM 
             (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
              UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         WHERE 
             CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, t.TagName
),
MostPopularTags AS (
    SELECT 
        TagName,
        SUM(TagCount) AS TotalUsage
    FROM 
        TagsCTE
    GROUP BY 
        TagName
    ORDER BY 
        TotalUsage DESC
    LIMIT 10
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName AS UserName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.Reputation > 100 
    GROUP BY 
        u.Id, u.DisplayName
),
TopContributors AS (
    SELECT 
        ue.UserId,
        ue.UserName,
        ue.QuestionCount,
        ue.CommentCount,
        ue.UpvoteCount,
        (ue.QuestionCount + ue.CommentCount + ue.UpvoteCount) AS TotalEngagement
    FROM 
        UserEngagement ue
    ORDER BY 
        TotalEngagement DESC
    LIMIT 5
)
SELECT 
    t.TagName,
    tc.UserName,
    tc.QuestionCount,
    tc.CommentCount,
    tc.UpvoteCount
FROM 
    MostPopularTags t
JOIN 
    TopContributors tc ON t.TotalUsage > 10 
ORDER BY 
    t.TagName, tc.TotalEngagement DESC;
