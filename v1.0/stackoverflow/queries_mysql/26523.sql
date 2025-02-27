
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
         UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
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
        @rank := IF(@prev_post_count = tc.PostCount, @rank, @rank + 1) AS TagRank,
        @prev_post_count := tc.PostCount
    FROM 
        TagCounts tc, (SELECT @rank := 0, @prev_post_count := NULL) r
    WHERE 
        tc.PostCount > 5
    ORDER BY 
        tc.PostCount DESC
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
        TopTags tt ON FIND_IN_SET(tt.Tag, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) > 0
    INNER JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
         UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
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
