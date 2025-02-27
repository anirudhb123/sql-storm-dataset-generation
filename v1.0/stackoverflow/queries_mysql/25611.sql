
WITH TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    INNER JOIN (
        SELECT 
            1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
            SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
            SELECT 9 UNION ALL SELECT 10 -- Adjust the range according to your needs
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        Tag
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(U.Reputation) AS TotalReputation,
        COUNT(DISTINCT P.Id) AS QuestionCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        Tag,
        PostCount
    FROM 
        TagCounts
    WHERE 
        PostCount > 5  
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.TotalReputation,
        @rank := @rank + 1 AS Rank
    FROM 
        UserReputation U, (SELECT @rank := 0) r
    JOIN 
        PopularTags T ON T.Tag IN (
            SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) 
            FROM Posts P 
            INNER JOIN Users U2 ON P.OwnerUserId = U2.Id 
            WHERE P.PostTypeId = 1
            GROUP BY P.OwnerUserId
        )
    ORDER BY 
        U.TotalReputation DESC
    LIMIT 10  
)
SELECT 
    U.DisplayName AS UserName,
    U.TotalReputation,
    T.Tag AS PopularTag,
    T.PostCount,
    U.Rank
FROM 
    TopUsers U
JOIN 
    PopularTags T ON T.Tag IN (
        SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) 
        FROM Posts P 
        JOIN Users U2 ON P.OwnerUserId = U2.Id 
        WHERE U2.Id = U.UserId AND P.PostTypeId = 1
    )
ORDER BY 
    U.Rank, T.PostCount DESC;
