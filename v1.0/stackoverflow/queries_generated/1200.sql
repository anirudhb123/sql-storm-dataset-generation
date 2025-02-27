WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(v.VoteTypeId = 2, 0)) AS UpVotes,
        SUM(COALESCE(v.VoteTypeId = 3, 0)) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TagPostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 50
),
UserRecommendations AS (
    SELECT 
        ua.DisplayName,
        tt.TagName,
        ROW_NUMBER() OVER (PARTITION BY ua.UserId ORDER BY tt.TagPostCount DESC) AS Rank
    FROM 
        UserActivity ua
    JOIN 
        TopTags tt ON ua.TotalUpVotes > 10
)
SELECT 
    ur.DisplayName,
    STRING_AGG(ur.TagName, ', ') AS RecommendedTags
FROM 
    UserRecommendations ur
WHERE 
    ur.Rank <= 3
GROUP BY 
    ur.DisplayName
ORDER BY 
    ur.DisplayName;
