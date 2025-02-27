
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
    CROSS APPLY (SELECT value AS tag FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')) AS tag
    JOIN 
        Tags t ON t.TagName = tag.tag
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
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
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
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
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
