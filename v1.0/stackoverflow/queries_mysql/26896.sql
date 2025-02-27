
WITH TagAggregation AS (
    SELECT 
        SPLIT_PART(tag.TNAME, '>', 1) AS MainTag,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(u.Reputation) AS AvgUserReputation,
        GROUP_CONCAT(DISTINCT u.DisplayName ORDER BY u.DisplayName SEPARATOR ', ') AS ActiveUsers
    FROM 
        Posts p
    JOIN 
        (SELECT DISTINCT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', n.n), '<', -1) AS TNAME
        FROM 
            Posts
        CROSS JOIN 
            (SELECT 1 as n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
             UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
        WHERE 
            n.n <= LENGTH(Tags) - LENGTH(REPLACE(Tags, '>', '')) + LENGTH(Tags) - LENGTH(REPLACE(Tags, '<', '')) + 1
        ) AS tag ON p.Tags LIKE CONCAT('%', tag.TNAME, '%')
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-10-01'
    GROUP BY 
        MainTag
), 
TopBadges AS (
    SELECT 
        b.Name AS BadgeName,
        COUNT(DISTINCT b.UserId) AS RecipientCount
    FROM 
        Badges b
    GROUP BY 
        b.Name
    ORDER BY 
        RecipientCount DESC
    LIMIT 5
)

SELECT 
    ta.MainTag,
    ta.PostCount,
    ta.AvgUserReputation,
    ta.ActiveUsers,
    tb.BadgeName,
    tb.RecipientCount
FROM 
    TagAggregation ta
LEFT JOIN 
    TopBadges tb ON ta.AvgUserReputation >= (
        SELECT 
            AVG(u.Reputation)
        FROM 
            Users u
        WHERE 
            u.Reputation IS NOT NULL
            AND u.Reputation < ta.AvgUserReputation
    )
ORDER BY 
    ta.PostCount DESC, 
    tb.RecipientCount DESC;
