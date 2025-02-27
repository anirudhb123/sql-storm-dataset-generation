WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COALESCE(SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalUpvotes,
        TotalDownvotes,
        TotalBadges,
        TotalPosts,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC, TotalUpvotes DESC) AS UserRank
    FROM 
        UserStats
), PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, ',')) AS TagName
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
), TagCounts AS (
    SELECT 
        TagName,
        COUNT(*) AS TagFrequency
    FROM 
        PopularTags
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5
), UserTagStats AS (
    SELECT 
        u.UserId,
        COUNT(DISTINCT t.TagName) AS CountOfTags
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    JOIN 
        PopularTags t ON t.TagName = ALL(string_to_array(p.Tags, ','))
    GROUP BY 
        u.UserId
)
SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.TotalUpvotes,
    ru.TotalDownvotes,
    ru.TotalBadges,
    ru.TotalPosts,
    ut.CountOfTags AS UniqueTags,
    tc.TagFrequency AS PopularTagFrequency
FROM 
    RankedUsers ru
LEFT JOIN 
    UserTagStats ut ON ru.UserId = ut.UserId
LEFT JOIN 
    TagCounts tc ON tc.TagName IN (
        SELECT
            unnest(string_to_array(p.Tags, ',')) 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = ru.UserId
    )
WHERE 
    ru.UserRank <= 10
ORDER BY 
    ru.Reputation DESC;
