
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
    FROM Posts p
    JOIN (SELECT a.N + b.N * 10 + 1 n
          FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
                UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
                UNION ALL SELECT 8 UNION ALL SELECT 9) a
          , (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
             UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
             UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE p.PostTypeId = 1  
),
TagStatistics AS (
    SELECT 
        Tag,
        COUNT(p.Id) AS PostCount,
        AVG(u.Reputation) AS AverageUserReputation,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueAuthors
    FROM PostTags pt
    JOIN Posts p ON pt.PostId = p.Id
    JOIN Users u ON p.OwnerUserId = u.Id
    GROUP BY Tag
),
TopTags AS (
    SELECT 
        Tag,
        PostCount,
        AverageUserReputation,
        UniqueAuthors,
        @rank := IF(@prevPostCount = PostCount, @rank, @rank + 1) AS TagRank,
        @prevPostCount := PostCount
    FROM TagStatistics, (SELECT @rank := 0, @prevPostCount := NULL) AS r
    WHERE PostCount > 1  
    ORDER BY PostCount DESC, AverageUserReputation DESC
)
SELECT 
    T.Tag,
    T.PostCount,
    ROUND(T.AverageUserReputation, 2) AS AverageUserReputation,
    T.UniqueAuthors,
    COUNT(c.Id) AS TotalComments,
    COUNT(v.Id) AS TotalVotes
FROM TopTags T
LEFT JOIN Posts p ON FIND_IN_SET(T.Tag, REPLACE(SUBSTRING(SUBSTRING_INDEX(p.Tags, '>', 1), 2), '><', ',')) AND p.PostTypeId = 1
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
WHERE T.TagRank <= 10 
GROUP BY T.Tag, T.PostCount, T.AverageUserReputation, T.UniqueAuthors, T.TagRank
ORDER BY T.TagRank;
