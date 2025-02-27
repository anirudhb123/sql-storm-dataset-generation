WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) -- Questions and Answers
    UNION ALL
    SELECT 
        p2.Id,
        p2.Title,
        p2.PostTypeId,
        p2.ParentId,
        r.Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostHierarchy r ON p2.ParentId = r.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        AVG(v.CreationDate - u.CreationDate) AS AvgPostAge
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.Reputation > 1000 -- Only considering users with reputation over 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS Tag
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Questions only
),
FrequentTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        TopTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    u.DisplayName,
    u.PostCount,
    u.TotalBounties,
    COALESCE(rt.Title, 'N/A') AS RecentTopPost,
    ft.Tag AS MostFrequentTag
FROM 
    UserActivity u
LEFT JOIN 
    (SELECT 
         p.Title,
         p.OwnerUserId
     FROM 
         Posts p
     WHERE 
         p.LastActivityDate = (SELECT MAX(LastActivityDate) FROM Posts WHERE OwnerUserId = p.OwnerUserId)
    ) rt ON rt.OwnerUserId = u.UserId
CROSS JOIN 
    FrequentTags ft
ORDER BY 
    u.TotalBounties DESC, 
    u.PostCount DESC;
