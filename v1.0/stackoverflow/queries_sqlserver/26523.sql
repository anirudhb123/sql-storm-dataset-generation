
WITH TagCounts AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE 
        PostTypeId = 1
    GROUP BY 
        value
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

TopTags AS (
    SELECT 
        tc.Tag,
        tc.PostCount,
        RANK() OVER (ORDER BY tc.PostCount DESC) AS TagRank
    FROM 
        TagCounts tc
    WHERE 
        tc.PostCount > 5
),

UserTagEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        tt.Tag,
        COUNT(DISTINCT p.Id) AS EngagedPosts
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    JOIN 
        TopTags tt ON tt.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><'))
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName, tt.Tag
)

SELECT 
    uge.UserId,
    uge.DisplayName,
    uge.Tag,
    uge.EngagedPosts,
    ur.Reputation,
    ur.QuestionCount,
    ur.VoteCount,
    ur.UpvoteCount,
    ur.DownvoteCount
FROM 
    UserTagEngagement uge
JOIN 
    UserReputation ur ON uge.UserId = ur.UserId
WHERE 
    uge.EngagedPosts > 1
ORDER BY 
    ur.Reputation DESC, uge.EngagedPosts DESC;
