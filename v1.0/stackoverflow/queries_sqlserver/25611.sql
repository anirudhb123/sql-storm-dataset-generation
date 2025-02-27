
WITH TagCounts AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS TagList
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        value
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
        ROW_NUMBER() OVER (ORDER BY U.TotalReputation DESC) AS Rank
    FROM 
        UserReputation U
    JOIN 
        PopularTags T ON T.Tag IN (
            SELECT value 
            FROM STRING_SPLIT(SUBSTRING(P.Tags, 2, LEN(P.Tags) - 2), '><') 
            FROM Posts P 
            WHERE P.PostTypeId = 1
        )
    ORDER BY 
        U.TotalReputation DESC
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
        SELECT value 
        FROM STRING_SPLIT(SUBSTRING(P.Tags, 2, LEN(P.Tags) - 2), '><') 
        FROM Posts P 
        JOIN Users U2 ON P.OwnerUserId = U2.Id 
        WHERE U2.Id = U.UserId AND P.PostTypeId = 1
    )
ORDER BY 
    U.Rank, T.PostCount DESC;
