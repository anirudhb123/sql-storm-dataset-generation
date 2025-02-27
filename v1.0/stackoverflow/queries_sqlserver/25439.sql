
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>') AS Tag
    FROM 
        Posts p
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
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        SUM(ISNULL(p.Score, 0)) AS TotalScore
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
            ROW_NUMBER() OVER(PARTITION BY pt.Tag ORDER BY u.Reputation DESC) AS rn
        FROM 
            PostTags pt
        JOIN 
            Posts p ON pt.PostId = p.Id
        JOIN 
            Users u ON p.OwnerUserId = u.Id
        LEFT JOIN 
            UserReputation b ON u.Id = b.UserId
    ) ur ON ta.Tag = ur.Tag AND ur.rn = 1
ORDER BY 
    ta.TotalViews DESC, 
    ta.TotalScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
