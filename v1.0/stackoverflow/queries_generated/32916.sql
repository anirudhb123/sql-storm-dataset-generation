WITH RecursiveTagHierarchy AS (
    SELECT 
        Id,
        TagName,
        Count,
        0 AS Level
    FROM 
        Tags
    WHERE 
        IsRequired = 1

    UNION ALL

    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        r.Level + 1
    FROM 
        Tags t
    INNER JOIN 
        RecursiveTagHierarchy r ON t.ExcerptPostId = r.Id
),

UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),

ClosePostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),

UserBadges AS (
    SELECT 
        b.UserId,
        ARRAY_AGG(DISTINCT b.Name) AS Badges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),

FinalMetrics AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostsCount,
        ups.TotalViews,
        ups.TotalScore,
        ups.AvgScore,
        COALESCE(cpr.CloseReasons, 'No Close Reasons') AS CloseReasons,
        COALESCE(ub.Badges, '{}'::varchar[]) AS Badges
    FROM 
        UserPostStats ups
    LEFT JOIN 
        ClosePostReasons cpr ON cpr.PostId = ups.UserId
    LEFT JOIN 
        UserBadges ub ON ub.UserId = ups.UserId
)

SELECT 
    *
FROM 
    FinalMetrics
WHERE 
    PostsCount > 5 AND 
    TotalViews > 1000
ORDER BY 
    AvgScore DESC, 
    TotalViews DESC
LIMIT 50;
