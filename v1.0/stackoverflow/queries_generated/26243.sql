WITH TagStats AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(Posts.ViewCount) AS TotalViews,
        AVG(Users.Reputation) AS AverageReputation
    FROM
        Tags 
        JOIN Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, '>'))
        LEFT JOIN Users ON Posts.OwnerUserId = Users.Id
    GROUP BY 
        Tags.TagName
), 
PostHistoryAggregates AS (
    SELECT 
        PostId,
        MAX(CASE WHEN PostHistoryTypeId = 10 THEN CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN PostHistoryTypeId = 24 THEN 1 END) AS SuggestionCount,
        COUNT(CASE WHEN PostHistoryTypeId = 52 THEN 1 END) AS HotCount
    FROM 
        PostHistory
    GROUP BY 
        PostId
)
SELECT 
    t.TagName,
    t.PostCount,
    t.TotalViews,
    t.AverageReputation,
    p.LastClosedDate,
    p.SuggestionCount,
    p.HotCount
FROM 
    TagStats t
LEFT JOIN 
    PostHistoryAggregates p ON t.PostCount > 0 -- Only linking via posts with non-zero count
WHERE 
    t.AverageReputation > (SELECT AVG(Reputation) FROM Users) -- Tags with higher than average owner reputation
ORDER BY 
    t.TotalViews DESC, t.PostCount DESC -- Sort by total views and then post count
LIMIT 10;

