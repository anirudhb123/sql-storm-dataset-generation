
WITH RecursiveTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
    FROM 
        Posts p
    INNER JOIN (
        SELECT 
            a.N + b.N * 10 + 1 AS n
        FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1  
),
AggregatedTags AS (
    SELECT 
        TagName,
        COUNT(*) AS TagUsageCount
    FROM 
        RecursiveTags
    GROUP BY 
        TagName
    ORDER BY 
        TagUsageCount DESC
    LIMIT 10
),
MostVotedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS Score
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title
    ORDER BY 
        Score DESC
    LIMIT 10
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        bc.BadgeCount,
        @rownum := @rownum + 1 AS UserRank
    FROM 
        Users u, (SELECT @rownum := 0) r, UserBadgeCounts bc
    WHERE 
        u.Id = bc.UserId AND u.Reputation > 1000  
    ORDER BY 
        u.Reputation DESC
)
SELECT 
    at.TagName,
    at.TagUsageCount,
    mvp.PostId,
    mvp.Title AS MostVotedPost,
    tu.DisplayName AS TopUser,
    tu.Reputation,
    tu.BadgeCount
FROM 
    AggregatedTags at
CROSS JOIN 
    MostVotedPosts mvp
CROSS JOIN 
    TopUsers tu
ORDER BY 
    at.TagUsageCount DESC, 
    mvp.Score DESC, 
    tu.Reputation DESC;
