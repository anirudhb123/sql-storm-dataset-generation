WITH TagAggregate AS (
    SELECT 
        TRIM(UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) ) AS TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END, 0)) AS QuestionCount,
        SUM(COALESCE(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END, 0)) AS AnswerCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViewCount
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalViewCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagAggregate
    WHERE 
        PostCount > 5
),
UserInteraction AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        COUNT(DISTINCT b.Id) AS BadgesEarned
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ut.DisplayName AS UserName,
    ut.PostsCreated,
    ut.CommentsMade,
    ut.BadgesEarned,
    tt.TagName,
    tt.PostCount,
    tt.QuestionCount,
    tt.AnswerCount,
    tt.TotalViewCount
FROM 
    UserInteraction ut
JOIN 
    TopTags tt ON ut.PostsCreated > 0
ORDER BY 
    tt.TagRank, ut.PostsCreated DESC
LIMIT 10;
