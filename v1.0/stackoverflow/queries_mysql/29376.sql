
WITH TagUsage AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS UsageCount,
        AVG(VoteCount) AS AvgVotes,
        COUNT(DISTINCT OwnerUserId) AS UniqueUsers
    FROM 
        Posts
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) AS VoteSummary ON Posts.Id = VoteSummary.PostId
    INNER JOIN (
        SELECT 
            1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
            SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
            SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL 
            SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 AND 
        Tags IS NOT NULL
    GROUP BY 
        Tag
),
TagStats AS (
    SELECT 
        Tag,
        SUM(UsageCount) AS TotalUsage,
        SUM(AvgVotes) AS TotalAvgVotes,
        SUM(UniqueUsers) AS TotalUniqueUsers
    FROM 
        TagUsage
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TotalUsage,
        TotalAvgVotes,
        TotalUniqueUsers,
        @rank := IF(@prev = TotalUsage, @rank, @rank + 1) AS TagRank,
        @prev := TotalUsage
    FROM 
        TagStats, (SELECT @rank := 0, @prev := NULL) AS vars
    ORDER BY 
        TotalUsage DESC
)
SELECT 
    T.Tag,
    T.TotalUsage,
    T.TotalAvgVotes,
    U.DisplayName,
    U.Reputation,
    B.Name AS BadgeName,
    B.Date AS BadgeDate
FROM 
    TopTags T
JOIN 
    Users U ON U.Id IN (SELECT OwnerUserId FROM Posts WHERE Tags LIKE CONCAT('%', T.Tag, '%'))
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    T.TagRank <= 10
ORDER BY 
    T.TotalUsage DESC, U.Reputation DESC;
