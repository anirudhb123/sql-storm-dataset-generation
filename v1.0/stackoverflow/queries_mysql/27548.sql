
WITH ParsedTags AS (
    SELECT 
        p.Id AS PostId, 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT @rownum := @rownum + 1 AS n FROM 
            (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION 
             SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION 
             SELECT 9 UNION SELECT 10) numbers,
            (SELECT @rownum := 0) r) numbers
    WHERE 
        p.PostTypeId = 1 AND CHAR_LENGTH(p.Tags) > 2
),
TagStatistics AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagCount,
        AVG(u.Reputation) AS AvgReputation,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers
    FROM 
        ParsedTags pt
    JOIN 
        Posts p ON pt.PostId = p.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        TagCount, 
        AvgReputation, 
        UniqueUsers,
        @rank := @rank + 1 AS TagRank
    FROM 
        TagStatistics, (SELECT @rank := 0) r
    ORDER BY 
        TagCount DESC
),
UserActivities AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tt.Tag,
    tt.TagCount,
    tt.AvgReputation,
    tt.UniqueUsers,
    ua.DisplayName AS ActiveUser,
    ua.QuestionsAsked,
    ua.CommentsMade,
    ua.TotalBounty,
    ua.TotalVotes
FROM 
    TopTags tt
JOIN 
    UserActivities ua ON ua.QuestionsAsked > 0
WHERE 
    tt.TagRank <= 10  
ORDER BY 
    tt.TagCount DESC, 
    ua.TotalVotes DESC;
