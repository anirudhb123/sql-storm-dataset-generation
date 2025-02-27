
WITH TagsSplit AS (
    SELECT 
        Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName
    FROM Posts
    INNER JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE Tags IS NOT NULL
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoters,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        AVG(u.Reputation) AS AvgUserReputation
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Users u ON v.UserId = u.Id
    WHERE p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
    GROUP BY p.Id, p.Title
),
TagPopularity AS (
    SELECT 
        ts.TagName,
        COUNT(DISTINCT ps.PostId) AS PostCount,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.UniqueVoters) AS TotalUniqueVoters,
        AVG(ps.AvgUserReputation) AS AvgUserReputation
    FROM TagsSplit ts
    JOIN PostStatistics ps ON ts.PostId = ps.PostId
    GROUP BY ts.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        TotalComments,
        TotalUniqueVoters,
        AvgUserReputation,
        @rownum := @rownum + 1 AS TagRank
    FROM TagPopularity, (SELECT @rownum := 0) r
    ORDER BY PostCount DESC
),
TrendingTags AS (
    SELECT 
        TagName,
        COUNT(*) AS TrendingPostCount,
        SUM(TotalComments) AS TrendingTotalComments
    FROM TopTags
    WHERE TagRank <= 10  
    GROUP BY TagName
)

SELECT 
    tt.TagName,
    tt.PostCount,
    tt.TotalComments,
    tt.TotalUniqueVoters,
    tt.AvgUserReputation,
    tr.TrendingPostCount,
    tr.TrendingTotalComments
FROM TopTags tt
LEFT JOIN TrendingTags tr ON tt.TagName = tr.TagName
ORDER BY tt.PostCount DESC;
