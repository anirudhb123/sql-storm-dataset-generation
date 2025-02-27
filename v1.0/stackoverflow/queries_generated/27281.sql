WITH TagStatistics AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore
    FROM
        Tags t
    LEFT JOIN
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY
        t.TagName
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.Reputation
),
TopTags AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.QuestionCount,
        ts.AnswerCount,
        ts.TotalViews,
        ts.TotalScore,
        ROW_NUMBER() OVER (ORDER BY ts.PostCount DESC) AS Rank
    FROM 
        TagStatistics ts
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.QuestionCount,
    tt.AnswerCount,
    tt.TotalViews,
    tt.TotalScore,
    ur.UserId,
    ur.Reputation,
    ur.PostsCreated,
    ur.TotalBadges
FROM 
    TopTags tt
JOIN 
    Posts p ON tt.TagName = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
JOIN 
    UserReputation ur ON p.OwnerUserId = ur.UserId
WHERE 
    tt.Rank <= 10
ORDER BY 
    tt.PostCount DESC, ur.Reputation DESC;
