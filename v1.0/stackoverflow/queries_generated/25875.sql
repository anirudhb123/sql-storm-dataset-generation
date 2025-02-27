WITH PostTagStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsList
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Tags t ON POSITION(t.TagName IN p.Tags) > 0
    WHERE p.PostTypeId = 1  -- Only questions
    GROUP BY p.Id, p.Title, p.Tags
),
TagUsage AS (
    SELECT 
        UNNEST(TagsList) AS TagName,
        COUNT(*) AS PostCount
    FROM PostTagStats
    GROUP BY TagName
),
MostCommonTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM TagUsage
)
SELECT 
    mct.TagName,
    mct.PostCount,
    COUNT(p.Title) AS RelatedPostCount,
    AVG(p.ViewCount) AS AverageViews,
    SUM(ub.Reputation) AS TotalReputation
FROM MostCommonTags mct
JOIN PostTagStats p ON POSITION(mct.TagName IN p.Tags) > 0
JOIN Users ub ON ub.Id = p.OwnerUserId
WHERE mct.TagRank <= 10  -- Top 10 tags
GROUP BY mct.TagName, mct.PostCount
ORDER BY mct.PostCount DESC;
