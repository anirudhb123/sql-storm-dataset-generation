WITH TagCounts AS (
    SELECT 
        Tag, 
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount 
    FROM (
        SELECT 
            unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
            PostTypeId 
        FROM 
            Posts
    ) AS ExtractedTags
    GROUP BY 
        Tag
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        QuestionCount,
        AnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE 
        PostCount > 10  -- Filter for popular tags
)
SELECT 
    ut.UserId,
    ut.DisplayName,
    ut.Reputation,
    tt.Tag,
    tt.PostCount AS TotalPosts,
    tt.QuestionCount AS TotalQuestions,
    tt.AnswerCount AS TotalAnswers,
    (ut.PostCount * 1.0 / NULLIF(tt.PostCount, 0)) AS UserTagPostRatio,
    ut.CommentCount AS TotalComments,
    ut.BadgeCount AS TotalBadges
FROM 
    UserReputation ut
JOIN 
    TopTags tt ON ut.UserId IN (
        SELECT DISTINCT OwnerUserId 
        FROM Posts 
        WHERE Tags LIKE '%' || tt.Tag || '%'
    )
WHERE 
    ut.Reputation > 100  -- Only consider users with a good reputation
ORDER BY 
    tt.PostCount DESC, ut.Reputation DESC;
