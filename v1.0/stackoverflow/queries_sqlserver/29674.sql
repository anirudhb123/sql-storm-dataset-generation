
WITH TagCount AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags)-2), '><')
    WHERE PostTypeId = 1
    GROUP BY value
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS QuestionCount,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.Score) AS TotalScore
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE P.PostTypeId = 1
    GROUP BY U.Id, U.DisplayName, U.Reputation
    ORDER BY TotalScore DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
Combined AS (
    SELECT 
        T.TagName,
        T.PostCount,
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.QuestionCount,
        U.TotalViews
    FROM TagCount T
    JOIN TopUsers U ON T.PostCount > 5
)
SELECT 
    C.TagName,
    C.PostCount,
    C.DisplayName AS TopUser,
    C.Reputation,
    C.QuestionCount,
    C.TotalViews
FROM Combined C
ORDER BY C.PostCount DESC, C.Reputation DESC;
