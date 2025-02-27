WITH TagCount AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Only considering questions
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCount
)
SELECT 
    t.Tag,
    t.PostCount,
    COALESCE(u.UserName, 'Unregistered') AS MostActiveUser,
    u.Reputation AS UserReputation,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score
FROM 
    TopTags t
JOIN 
    Posts p ON p.Tags LIKE '%' || t.Tag || '%'
JOIN 
    (SELECT 
         OwnerUserId,
         COUNT(*) AS UserPostCount
     FROM 
         Posts
     WHERE 
         PostTypeId = 1 
     GROUP BY 
         OwnerUserId
     ORDER BY 
         UserPostCount DESC 
     LIMIT 1) AS top_user ON p.OwnerUserId = top_user.OwnerUserId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    t.Rank <= 10  -- Only get top 10 tags
ORDER BY 
    t.PostCount DESC, p.ViewCount DESC;
