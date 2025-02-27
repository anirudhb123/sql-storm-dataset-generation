WITH TagStats AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only considering questions
    GROUP BY 
        Tag
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        ts.Tag,
        ts.PostCount,
        RANK() OVER (ORDER BY ts.PostCount DESC) AS TagRank
    FROM 
        TagStats ts
)
SELECT 
    ua.UserId,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.Upvotes,
    ua.Downvotes,
    pt.Tag,
    pt.PostCount AS AssociatedPostCount
FROM 
    UserActivity ua
JOIN 
    PopularTags pt ON pt.Tag IN (SELECT UNNEST(string_to_array(substring((SELECT Tags FROM Posts WHERE Id IN (SELECT PostId FROM PostLinks WHERE RelatedPostId = ua.UserId)), 2, length((SELECT Tags FROM Posts WHERE Id IN (SELECT PostId FROM PostLinks WHERE RelatedPostId = ua.UserId)))-2), '><')))
WHERE 
    pt.TagRank <= 10
ORDER BY 
    ua.Upvotes DESC, ua.QuestionCount DESC;
