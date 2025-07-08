
WITH Tag_List AS (
    SELECT 
        SPLIT_PART(tag, '>', 1) AS TagName,
        COUNT(*) AS TagCount
    FROM (
        SELECT 
            TRIM(SEGMENT) AS tag,
            Id
        FROM (
            SELECT 
                FLATTEN(INPUT => SPLIT(SUBSTR(Tags, 2, LEN(Tags) - 2), '><')) AS SEQ,
                Id
            FROM Posts
            WHERE PostTypeId = 1  
        )
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
    WHERE p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56'::timestamp)
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
JOIN Top_Tags tt ON TRUE  
WHERE au.UpVotes > 10  
ORDER BY au.PostCount DESC, tt.TagCount DESC
LIMIT 10;
