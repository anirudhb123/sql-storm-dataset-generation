WITH TagStats AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><'))) AS Tag,
        COUNT(Id) AS PostCount,
        COUNT(DISTINCT OwnerUserId) AS UniqueUsers,
        SUM(ViewCount) AS TotalViews
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only considering Questions
    GROUP BY 
        Tag
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(p.ViewCount) AS TotalViews,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        ARRAY_AGG(DISTINCT crt.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment::int = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId
),
PopularTags AS (
    SELECT 
        Tag,
        PostCount,
        UniqueUsers,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS Rank
    FROM 
        TagStats
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
    PopularTags pt ON pt.Rank <= 5 -- Get top 5 popular tags
LEFT JOIN 
    CloseReasons cr ON ut.QuestionsAsked = cr.PostId
WHERE 
    ut.TotalViews > 1000 -- User's total views should be more than 1000
ORDER BY 
    ut.TotalViews DESC, 
    pt.Tag;
