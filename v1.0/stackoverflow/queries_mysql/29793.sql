
WITH Tag_List AS (
    SELECT 
        SUBSTRING_INDEX(tag, '>', 1) AS TagName,
        COUNT(*) AS TagCount
    FROM (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS tag,
            Id
        FROM Posts
        JOIN (
            SELECT 
                a.N + b.N * 10 + 1 n
            FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
            CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
        ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
        WHERE PostTypeId = 1  
    ) AS Tags_Sub
    GROUP BY TagName
),
Active_Users AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY u.Id, u.DisplayName
),
Top_Tags AS (
    SELECT 
        TagName,
        TagCount,
        @rownum := @rownum + 1 AS TagRank
    FROM Tag_List, (SELECT @rownum := 0) r
    WHERE TagCount > 5  
)
SELECT 
    au.DisplayName AS ActiveUser,
    au.PostCount AS NumberOfPosts,
    au.UpVotes AS TotalUpVotes,
    au.DownVotes AS TotalDownVotes,
    tt.TagName AS MostUsedTag,
    tt.TagCount AS UsageCount
FROM Active_Users au
JOIN Top_Tags tt ON TRUE  
WHERE au.UpVotes > 10  
ORDER BY au.PostCount DESC, tt.TagCount DESC
LIMIT 10;
