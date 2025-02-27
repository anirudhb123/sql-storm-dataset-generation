WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        SUM(CASE WHEN p.PostTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TagWikiCount,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AverageScore,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopContributors
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        t.TagName
), BadgeStatistics AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
), PostHistoryStatistics AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS RevisionCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS RevisionTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)

SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.WikiCount,
    ts.TagWikiCount,
    ts.TotalViews,
    ts.AverageScore,
    bs.BadgeCount,
    bs.BadgeNames,
    phs.RevisionCount,
    phs.RevisionTypes
FROM 
    TagStatistics ts
LEFT JOIN 
    BadgeStatistics bs ON bs.UserId IN (
        SELECT DISTINCT p.OwnerUserId 
        FROM Posts p 
        WHERE p.Tags LIKE '%' || ts.TagName || '%'
    )
LEFT JOIN 
    PostHistoryStatistics phs ON phs.PostId IN (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.Tags LIKE '%' || ts.TagName || '%'
    )
ORDER BY 
    ts.PostCount DESC;
