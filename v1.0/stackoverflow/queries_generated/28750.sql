WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(p.ViewCount, 0)) AS AvgViews,
        AVG(COALESCE(c.Score, 0)) AS AvgCommentScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        AvgViews,
        AvgCommentScore,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
    WHERE 
        PostCount > 0
),
FrequentTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        AvgViewCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        FrequentTags
)
SELECT 
    u.DisplayName,
    u.Reputation AS UserReputation,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    u.AvgViews AS UserAvgViews,
    u.AvgCommentScore AS UserAvgCommentScore,
    t.TagName,
    t.PostCount AS TagPostCount,
    t.AvgViewCount AS TagAvgViewCount
FROM 
    TopUsers u
JOIN 
    TopTags t ON u.PostCount > 10 AND u.Reputation > 1000
WHERE 
    u.ReputationRank <= 10 AND t.TagRank <= 5
ORDER BY 
    u.Reputation DESC, t.PostCount DESC;
