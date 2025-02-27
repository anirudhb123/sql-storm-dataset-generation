WITH TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),

ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS ContributionCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS DownVotes
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    tg.TagName,
    tg.PostCount,
    au.UserId,
    au.DisplayName,
    au.Reputation,
    au.ContributionCount,
    au.UpVotes,
    au.DownVotes
FROM 
    TagCounts tg
JOIN 
    ActiveUsers au ON tg.TagName ILIKE '%' || au.DisplayName || '%'
ORDER BY 
    tg.PostCount DESC, 
    au.Reputation DESC
LIMIT 10;
