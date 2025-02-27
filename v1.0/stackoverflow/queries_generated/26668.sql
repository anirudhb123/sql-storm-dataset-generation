WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName AS UserName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN a.Id IS NOT NULL THEN a.Id END) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TagStats AS (
    SELECT 
        t.Tag,
        COUNT(pt.Tag) AS TagUsage,
        COUNT(DISTINCT pa.PostId) AS PostCount
    FROM 
        PostTags pt
    JOIN 
        Tags t ON pt.Tag = t.TagName
    LEFT JOIN 
        Posts pa ON pa.Id = pt.PostId
    WHERE 
        pa.PostTypeId = 1
    GROUP BY 
        t.Tag
)
SELECT 
    ua.UserName,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.CommentCount,
    ua.TotalBounty,
    ts.Tag,
    ts.TagUsage,
    ts.PostCount
FROM 
    UserActivity ua
JOIN 
    TagStats ts ON ua.QuestionCount > 0
ORDER BY 
    ua.TotalBounty DESC, ts.TagUsage DESC;
