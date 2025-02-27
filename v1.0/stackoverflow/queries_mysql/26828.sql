
WITH TagStats AS (
    SELECT 
        TRIM(UNNEST(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)) AS Tag,
        COUNT(Id) AS PostCount,
        COUNT(DISTINCT OwnerUserId) AS UniqueUsers,
        SUM(ViewCount) AS TotalViews
    FROM 
        Posts
    JOIN 
        (SELECT a.N + b.N * 10 AS n 
         FROM (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) AS a 
         CROSS JOIN (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) AS b) n
    WHERE 
        PostTypeId = 1 
        AND CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    GROUP BY 
        Tag
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(p.ViewCount) AS TotalViews,
        SUM(IFNULL(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        GROUP_CONCAT(DISTINCT crt.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment = CAST(crt.Id AS CHAR)
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
PopularTags AS (
    SELECT 
        Tag,
        PostCount,
        UniqueUsers,
        TotalViews,
        @rank := @rank + 1 AS Rank
    FROM 
        TagStats,
        (SELECT @rank := 0) r
    ORDER BY 
        TotalViews DESC
)
SELECT 
    ut.DisplayName AS User,
    ut.QuestionsAsked,
    ut.TotalViews AS UserTotalViews,
    ut.TotalBadges,
    pt.Tag AS PopularTag,
    pt.PostCount AS TagPostCount,
    pt.UniqueUsers AS TagUserCount,
    pt.TotalViews AS TagTotalViews,
    cr.CloseCount AS NumberOfClosures,
    cr.CloseReasons
FROM 
    UserStats ut
JOIN 
    PopularTags pt ON pt.Rank <= 5 
LEFT JOIN 
    CloseReasons cr ON ut.QuestionsAsked = cr.PostId
WHERE 
    ut.TotalViews > 1000 
ORDER BY 
    ut.TotalViews DESC, 
    pt.Tag;
