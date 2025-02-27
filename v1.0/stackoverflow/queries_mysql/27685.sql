
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        TRIM(UNNEST(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS TagName
    FROM 
        Posts p
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
        ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
        AND p.Tags IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostViews AS (
    SELECT 
        p.Id AS PostId, 
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
),
AggregatedData AS (
    SELECT 
        pt.TagName, 
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(pv.TotalViews) AS TotalViewCount,
        AVG(ur.Reputation) AS AvgUserReputation,
        SUM(ur.BadgeCount) AS TotalBadges
    FROM 
        PostTags pt
    JOIN 
        Posts p ON pt.PostId = p.Id
    JOIN 
        PostViews pv ON pv.PostId = p.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        UserReputation ur ON ur.UserId = u.Id
    GROUP BY 
        pt.TagName
)
SELECT 
    TagName, 
    QuestionCount, 
    TotalViewCount, 
    AvgUserReputation, 
    TotalBadges
FROM 
    AggregatedData
ORDER BY 
    QuestionCount DESC, 
    TotalViewCount DESC;
