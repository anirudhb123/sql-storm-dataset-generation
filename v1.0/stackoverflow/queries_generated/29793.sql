WITH Tag_List AS (
    SELECT 
        split_part(tag, '>', 1) AS TagName,
        COUNT(*) AS TagCount
    FROM (
        SELECT 
            unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS tag,
            Id
        FROM Posts
        WHERE PostTypeId = 1  -- Only questions
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
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY u.Id, u.DisplayName
),
Top_Tags AS (
    SELECT 
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM Tag_List
    WHERE TagCount > 5  -- Filter for tags used more than 5 times
)
SELECT 
    au.DisplayName AS ActiveUser,
    au.PostCount AS NumberOfPosts,
    au.UpVotes AS TotalUpVotes,
    au.DownVotes AS TotalDownVotes,
    tt.TagName AS MostUsedTag,
    tt.TagCount AS UsageCount
FROM Active_Users au
JOIN Top_Tags tt ON TRUE  -- Joining with all top tags to get usage
WHERE au.UpVotes > 10  -- Condition to filter active users with more than 10 upvotes
ORDER BY au.PostCount DESC, tt.TagCount DESC
LIMIT 10;
