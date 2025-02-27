
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
         SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
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
TagActivity AS (
    SELECT 
        pt.Tag,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        PostTags pt
    JOIN 
        Posts p ON pt.PostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    GROUP BY 
        pt.Tag
)
SELECT 
    ta.Tag,
    ta.PostCount,
    ta.CommentCount,
    ta.TotalViews,
    ta.TotalScore,
    COALESCE(ur.DisplayName, 'No Users') AS TopUser,
    COALESCE(ur.Reputation, 0) AS TopUserReputation,
    ur.BadgeCount AS TopUserBadgeCount
FROM 
    TagActivity ta
LEFT JOIN 
    (
        SELECT 
            pt.Tag,
            u.DisplayName,
            u.Reputation,
            b.BadgeCount,
            @rn := IF(@prevTag = pt.Tag, @rn + 1, 1) AS rn,
            @prevTag := pt.Tag
        FROM 
            PostTags pt
        JOIN 
            Posts p ON pt.PostId = p.Id
        JOIN 
            Users u ON p.OwnerUserId = u.Id
        LEFT JOIN 
            UserReputation b ON u.Id = b.UserId
        CROSS JOIN 
            (SELECT @rn := 0, @prevTag := NULL) r
        ORDER BY 
            pt.Tag, u.Reputation DESC
    ) ur ON ta.Tag = ur.Tag AND ur.rn = 1
ORDER BY 
    ta.TotalViews DESC, 
    ta.TotalScore DESC
LIMIT 10;
