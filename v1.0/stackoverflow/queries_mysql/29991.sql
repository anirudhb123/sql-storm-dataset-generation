
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
        UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TagPopularity AS (
    SELECT 
        pt.Tag,
        COUNT(pt.PostId) AS NumberOfPosts
    FROM 
        PostTags pt
    GROUP BY 
        pt.Tag
    ORDER BY 
        NumberOfPosts DESC
    LIMIT 10 
)
SELECT 
    u.DisplayName,
    u.Reputation,
    us.QuestionsAsked,
    us.TotalUpVotes,
    us.TotalDownVotes,
    tp.Tag,
    tp.NumberOfPosts
FROM 
    Users u
JOIN 
    UserStats us ON u.Id = us.UserId
JOIN 
    TagPopularity tp ON tp.Tag IN (
        SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)
        FROM Posts p 
        JOIN (
            SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
            UNION ALL SELECT 9 UNION ALL SELECT 10
        ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        WHERE p.OwnerUserId = u.Id AND p.PostTypeId = 1
    )
ORDER BY 
    us.TotalUpVotes DESC, 
    us.QuestionsAsked DESC;
