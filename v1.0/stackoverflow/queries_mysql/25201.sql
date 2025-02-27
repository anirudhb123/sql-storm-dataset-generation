
WITH TagCounts AS (
    SELECT 
        TRIM(UNNEST(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
), 
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
    WHERE 
        PostCount > 1
), 
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.OwnerUserId = U.Id THEN P.Score ELSE 0 END) AS TotalScore,
        SUM(B.Class) AS BadgeScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        SUM(P.Score) > 0 OR SUM(B.Class) > 0
)
SELECT 
    TT.TagName,
    TT.PostCount,
    UR.DisplayName,
    UR.TotalScore,
    UR.BadgeScore
FROM 
    TopTags TT
JOIN 
    UserReputation UR ON UR.TotalScore > (SELECT AVG(TotalScore) FROM UserReputation)
WHERE 
    TT.Rank <= 10
ORDER BY 
    TT.PostCount DESC, 
    UR.TotalScore DESC;
