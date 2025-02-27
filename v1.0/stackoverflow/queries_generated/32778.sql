WITH RecursiveTagCounts AS (
    SELECT 
        Tags.Id AS TagId,
        Tags.TagName,
        Tags.Count,
        1 AS Level
    FROM Tags
    WHERE Tags.Count > 10

    UNION ALL

    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        rtc.Level + 1
    FROM Tags t
    INNER JOIN RecursiveTagCounts rtc ON t.Count < rtc.Count
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    SUM(COALESCE(b.Class, 0)) AS TotalBadges,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    AVG(p.Score) AS AveragePostScore,
    STRING_AGG(DISTINCT tt.TagName, ', ') AS TagsUsed,
    MAX(p.CreationDate) AS LastPostDate
FROM Users u
LEFT JOIN Badges b ON u.Id = b.UserId
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN Comments c ON u.Id = c.UserId
LEFT JOIN Posts pt ON p.Id = pt.ParentId -- Join for related posts
LEFT JOIN (
    SELECT 
        p.Id,
        unnest(string_to_array(p.Tags, ',')) AS TagName
    FROM Posts p
) tt ON p.Id = tt.Id
LEFT JOIN RecursiveTagCounts rtc ON tt.TagName = rtc.TagName AND rtc.Level = 2
WHERE 
    u.Reputation > 100 AND 
    EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = p.Id 
        AND v.VoteTypeId = 2
    ) AND
    (u.Location IS NOT NULL AND u.Location <> '')
GROUP BY 
    u.Id, 
    u.DisplayName
ORDER BY 
    TotalBadges DESC, 
    TotalPosts DESC
FETCH FIRST 50 ROWS ONLY;
