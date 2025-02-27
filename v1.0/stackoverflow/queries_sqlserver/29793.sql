
WITH Tag_List AS (
    SELECT 
        LEFT(tag, CHARINDEX('>', tag) - 1) AS TagName,
        COUNT(*) AS TagCount
    FROM (
        SELECT 
            value AS tag,
            Id
        FROM Posts
        CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') 
        WHERE PostTypeId = 1  
    ) AS Tags_Sub
    GROUP BY LEFT(tag, CHARINDEX('>', tag) - 1
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
    WHERE p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY u.Id, u.DisplayName
),
Top_Tags AS (
    SELECT 
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM Tag_List
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
JOIN Top_Tags tt ON 1 = 1  
WHERE au.UpVotes > 10  
ORDER BY au.PostCount DESC, tt.TagCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
