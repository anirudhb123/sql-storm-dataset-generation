
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN (
        SELECT a.N + b.N * 10 + 1 AS n
        FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
    ) n
    WHERE 
        n.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1
        AND p.PostTypeId = 1 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT ph.PostId) AS TotalEdits,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS TitleBodyTagEdits 
    FROM 
        Users u
    JOIN 
        PostHistory ph ON u.Id = ph.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TagStatistics AS (
    SELECT 
        pt.Tag,
        COUNT(p.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN p.Id END) AS ClosedPostCount, 
        AVG(u.Reputation) AS AvgUserReputation 
    FROM 
        PostTags pt
    LEFT JOIN 
        Posts p ON pt.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Users u ON ph.UserId = u.Id
    GROUP BY 
        pt.Tag
),
FinalBenchmark AS (
    SELECT 
        ts.Tag,
        ts.PostCount,
        ts.ClosedPostCount,
        ts.AvgUserReputation,
        CASE 
            WHEN ts.PostCount > 0 THEN (ts.ClosedPostCount / ts.PostCount) * 100 
            ELSE 0 
        END AS ClosedPostPercentage
    FROM 
        TagStatistics ts
)
SELECT 
    fb.Tag,
    fb.PostCount,
    fb.ClosedPostCount,
    fb.AvgUserReputation,
    fb.ClosedPostPercentage
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.ClosedPostPercentage DESC
LIMIT 10;
