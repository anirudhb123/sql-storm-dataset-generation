WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS UsageCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = p.Id
    GROUP BY 
        t.TagName
    ORDER BY 
        UsageCount DESC
    LIMIT 10
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.BadgeCount,
    us.UpVotes,
    us.DownVotes,
    STRING_AGG(pt.TagName, ', ') AS PopularTags
FROM 
    UserStats us
LEFT JOIN 
    PopularTags pt ON us.UserId IN (SELECT OwnerUserId FROM Posts WHERE Tags LIKE '%' || pt.TagName || '%')
GROUP BY 
    us.UserId, us.DisplayName, us.Reputation, us.PostCount, us.BadgeCount, us.UpVotes, us.DownVotes
ORDER BY 
    us.Reputation DESC
LIMIT 50;
