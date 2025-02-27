WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        1 AS Level
    FROM 
        Users u
    WHERE 
        u.Reputation > 0
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.Reputation * 0.9 AS Reputation,
        u.DisplayName,
        Level + 1
    FROM 
        Users u
    JOIN 
        UserReputationCTE cte ON cte.UserId = u.Id
    WHERE 
        u.Reputation * 0.9 > 0
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(COM.CommentCount, 0) AS CommentCount,
        CASE 
            WHEN p.Score IS NULL THEN 0
            ELSE p.Score
        END AS Score
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount 
        FROM 
            Comments
        GROUP BY PostId
    ) COM ON p.Id = COM.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
),
TopTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation AS UserReputation,
    pp.Title AS PopularPostTitle,
    pp.ViewCount AS PopularPostViewCount,
    pp.CommentCount AS PopularPostCommentCount,
    tt.TagName AS TopTag,
    tt.PostCount AS TopPostsCount,
    RANK() OVER (PARTITION BY tt.TagName ORDER BY pp.Score DESC) AS PostRank
FROM 
    Users u
JOIN 
    UserReputationCTE ur ON u.Id = ur.UserId
JOIN 
    PopularPosts pp ON pp.Score > 10
JOIN 
    TopTags tt ON pp.Title LIKE '%' || tt.TagName || '%'
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    u.Reputation DESC, 
    pp.ViewCount DESC;
