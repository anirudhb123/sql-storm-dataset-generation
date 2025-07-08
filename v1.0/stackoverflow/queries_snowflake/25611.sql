
WITH TagCounts AS (
    SELECT 
        TRIM(BOTH '>' FROM TAG) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        (SELECT 
             SPLIT(REPLACE(REPLACE(Tags, '><', '|'), '>', ''), '<', '|')) AS Tag
         FROM Posts
         WHERE PostTypeId = 1) AS SplitTags
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
        ROW_NUMBER() OVER (ORDER BY U.TotalReputation DESC) AS Rank
    FROM 
        UserReputation U
    JOIN 
        PopularTags T ON T.Tag IN (
            SELECT TRIM(BOTH '>' FROM TAG) 
            FROM 
                (SELECT 
                     SPLIT(REPLACE(REPLACE(P.Tags, '><', '|'), '>', ''), '<', '|')) AS Tag
                 FROM Posts P 
                 WHERE P.PostTypeId = 1)
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
        SELECT TRIM(BOTH '>' FROM TAG) 
        FROM 
            (SELECT 
                 SPLIT(REPLACE(REPLACE(P.Tags, '><', '|'), '>', ''), '<', '|')) AS Tag
             FROM Posts P 
             JOIN Users U2 ON P.OwnerUserId = U2.Id 
             WHERE U2.Id = U.UserId AND P.PostTypeId = 1)
    )
ORDER BY 
    U.Rank, T.PostCount DESC;
