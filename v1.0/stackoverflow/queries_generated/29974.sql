WITH ProcessedTags AS (
    SELECT
        Id AS TagId,
        TagName,
        Count,
        EXTRACT(MONTH FROM CreationDate) AS MonthCreated,
        (SELECT COUNT(*) FROM Posts WHERE Tags LIKE '%' || TagName || '%') AS PostCount
    FROM Tags
),
TagUsageStats AS (
    SELECT
        TagId,
        TagName,
        COUNT(PostId) AS UsageCount,
        SUM(CASE WHEN PostCount > 0 THEN 1 ELSE 0 END) AS PostsWithTag
    FROM PostLinks
    INNER JOIN ProcessedTags ON ProcessedTags.TagId = PostLinks.RelatedPostId
    GROUP BY TagId, TagName
),
PopularTags AS (
    SELECT
        TagName,
        UsageCount,
        PostsWithTag,
        ROW_NUMBER() OVER (ORDER BY UsageCount DESC) AS TagRank
    FROM TagUsageStats
    WHERE UsageCount > 0
)
SELECT
    pt.TagName,
    pt.UsageCount,
    pt.PostsWithTag,
    SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCounts,
    SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCounts,
    AVG(u.Reputation) AS AvgUserReputation
FROM PopularTags pt
LEFT JOIN PostLinks pl ON pl.RelatedPostId = pt.TagId
LEFT JOIN Posts p ON p.Id = pl.PostId
LEFT JOIN PostHistory ph ON ph.PostId = p.Id
LEFT JOIN Users u ON u.Id = p.OwnerUserId
WHERE pt.TagRank <= 10
GROUP BY pt.TagName, pt.UsageCount, pt.PostsWithTag
ORDER BY pt.UsageCount DESC;
