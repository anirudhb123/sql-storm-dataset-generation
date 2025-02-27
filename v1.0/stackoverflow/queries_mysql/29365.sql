
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        Id AS PostId
    FROM 
        Posts
    JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
        UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 
        UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 
        UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1  
),
TagStatistics AS (
    SELECT 
        Tag, 
        COUNT(DISTINCT PostId) AS PostCount, 
        COUNT(*) AS TotalOccurrences
    FROM 
        TagCounts
    GROUP BY 
        Tag
),
UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(b.Class) AS TotalBadgeClass
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges b ON U.Id = b.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopTags AS (
    SELECT 
        Tag, 
        PostCount,
        TotalOccurrences,
        @row_number := @row_number + 1 AS TagRank
    FROM 
        TagStatistics, (SELECT @row_number := 0) AS r
    WHERE 
        TotalOccurrences > 1  
),
PopularUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        TotalBadgeClass,
        @user_rank := @user_rank + 1 AS UserRank
    FROM 
        UserReputation, (SELECT @user_rank := 0) AS r
)
SELECT 
    T.Tag, 
    T.PostCount, 
    T.TotalOccurrences,
    U.DisplayName AS TopUser,
    U.Reputation AS UserReputation,
    U.TotalBadgeClass AS UserTotalBadgeClass
FROM 
    TopTags T
JOIN 
    PopularUsers U ON U.PostCount > 1  
WHERE 
    T.TagRank <= 10  
ORDER BY 
    T.TotalOccurrences DESC;
