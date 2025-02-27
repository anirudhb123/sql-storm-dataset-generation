
WITH TagPostCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT a.N + b.N * 10 + 1 n
         FROM 
           (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
           (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) numbers 
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)
),
UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = 1)
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        tc.TagName,
        tc.PostCount,
        @rank := @rank + 1 AS PopularityRank
    FROM 
        TagPostCounts tc, (SELECT @rank := 0) r
    WHERE 
        tc.PostCount > 5  
    ORDER BY 
        tc.PostCount DESC
),
UserTagIntersections AS (
    SELECT 
        um.UserId,
        mt.TagName
    FROM 
        UserMetrics um
    JOIN 
        PopularTags mt ON um.QuestionCount > 0  
)
SELECT 
    ut.UserId,
    u.DisplayName,
    GROUP_CONCAT(DISTINCT ut.TagName ORDER BY ut.TagName SEPARATOR ', ') AS PopularTags,
    SUM(um.TotalBounties) AS SumOfBounties,
    SUM(um.TotalUpVotes) AS UpVoteSum,
    SUM(um.TotalDownVotes) AS DownVoteSum
FROM 
    UserTagIntersections ut
JOIN 
    UserMetrics um ON ut.UserId = um.UserId
JOIN 
    Users u ON um.UserId = u.Id
GROUP BY 
    ut.UserId, u.DisplayName
ORDER BY 
    UpVoteSum DESC, SumOfBounties DESC
LIMIT 10;
