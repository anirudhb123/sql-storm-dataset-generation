
WITH TagAggregation AS (
    SELECT 
        LEFT(tag.TNAME, CHARINDEX('>', tag.TNAME + '>') - 1) AS MainTag,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(u.Reputation) AS AvgUserReputation,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS ActiveUsers
    FROM 
        Posts p
    JOIN 
        (SELECT DISTINCT 
            VALUE AS TNAME 
        FROM 
            STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')) AS tag) ON p.Tags LIKE '%' + tag.TNAME + '%'
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2023-10-01'
    GROUP BY 
        LEFT(tag.TNAME, CHARINDEX('>', tag.TNAME + '>') - 1)
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
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
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
