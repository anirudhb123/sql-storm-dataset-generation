WITH RankedPosts AS (
    SELECT p.Id,
           p.Title,
           p.Body,
           p.CreationDate,
           p.ViewCount,
           p.Score,
           u.DisplayName AS OwnerDisplayName,
           ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankScore
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 
    AND p.CreationDate >= (CURRENT_DATE - INTERVAL '1 year')
),
TagStats AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags FROM 2 FOR length(p.Tags) - 2), '><')) AS Tag,
        COUNT(*) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(p.Score) AS AvgScore
    FROM Posts p
    WHERE p.PostTypeId = 1 
    GROUP BY Tag
),
PostDetails AS (
    SELECT p.Id,
           p.Title,
           p.Body,
           COUNT(c.Id) AS CommentCount,
           COUNT(v.Id) AS VoteCount,
           MAX(b.Class) AS HighestBadge
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.PostTypeId = 1
    GROUP BY p.Id, p.Title, p.Body
),
AggregatedData AS (
    SELECT r.Title,
           r.OwnerDisplayName,
           COUNT(p.Id) AS TotalPosts,
           SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
           AVG(COALESCE(p.Score, 0)) AS AvgScore,
           MAX(p.CreationDate) AS LastActiveDate
    FROM RankedPosts r
    JOIN PostDetails p ON r.Id = p.Id
    GROUP BY r.Title, r.OwnerDisplayName
)
SELECT a.OwnerDisplayName,
       a.TotalPosts,
       a.TotalViews,
       a.AvgScore,
       ts.Tag,
       ts.PostCount,
       ts.AvgViewCount,
       ts.AvgScore AS AvgTagScore
FROM AggregatedData a
JOIN TagStats ts ON ts.Tag IN (SELECT unnest(string_to_array(a.Title, ' ')))
ORDER BY a.AvgScore DESC, ts.PostCount DESC
LIMIT 100;
