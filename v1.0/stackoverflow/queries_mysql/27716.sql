
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN (
        SELECT 
            1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
        ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
),

PopularTags AS (
    SELECT 
        TagName,
        PostCount,
        @TagRank := @TagRank + 1 AS TagRank
    FROM 
        TagCounts, (SELECT @TagRank := 0) AS r
    WHERE 
        PostCount > 5 
    ORDER BY 
        PostCount DESC
),

UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvotesReceived,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        UpvotesReceived,
        DownvotesReceived,
        BadgesCount,
        @UserRank := @UserRank + 1 AS UserRank
    FROM 
        UserEngagement, (SELECT @UserRank := 0) AS r
    WHERE 
        QuestionCount > 0
    ORDER BY 
        UpvotesReceived DESC, QuestionCount DESC
)

SELECT 
    t.TagName,
    t.PostCount,
    u.DisplayName AS TopUser,
    u.UpvotesReceived,
    u.QuestionCount,
    u.BadgesCount
FROM 
    PopularTags t
JOIN 
    TopUsers u ON EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE 
            p.OwnerUserId = u.UserId 
            AND p.PostTypeId = 1 
            AND p.Tags LIKE CONCAT('%', t.TagName, '%')
    )
WHERE 
    t.TagRank <= 10 
ORDER BY 
    t.PostCount DESC, 
    u.UpvotesReceived DESC;
