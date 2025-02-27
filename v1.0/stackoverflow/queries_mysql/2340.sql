
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        u.Reputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT 
        TRIM(BOTH '{}' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts 
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
        SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL 
        SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL 
        SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.UpVotes,
    us.DownVotes,
    us.TotalPosts,
    us.TotalComments,
    COALESCE(pt.TagCount, 0) AS PopularTagCount
FROM 
    UserStats us
LEFT JOIN 
    PopularTags pt ON us.TotalPosts > 2 AND us.DisplayName LIKE CONCAT('%', pt.TagName, '%')
WHERE 
    us.Reputation > 100
ORDER BY 
    us.TotalPosts DESC,
    us.UpVotes DESC;
