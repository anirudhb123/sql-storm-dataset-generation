SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
    ARRAY_AGG(DISTINCT t.TagName) AS TagsUsed,
    MAX(ph.CreationDate) AS LastPostDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(p.Tags, '><')) AS TagName
        WHERE 
            p.PostTypeId = 1
    ) t ON true
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    u.CreationDate > CURRENT_DATE - INTERVAL '1 year'
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) > 10
ORDER BY 
    u.Reputation DESC;
