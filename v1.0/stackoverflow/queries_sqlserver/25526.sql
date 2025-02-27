
WITH TagFrequency AS (
    SELECT 
        LTRIM(RTRIM(PARSENAME(REPLACE(tag, '>', '.'), 1))) AS TagName,
        COUNT(*) AS Frequency
    FROM (
        SELECT VALUE AS tag
        FROM STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    ) AS TagList
    WHERE (SELECT TOP 1 PostTypeId FROM Posts WHERE PostTypeId = 1) IS NOT NULL
    GROUP BY LTRIM(RTRIM(PARSENAME(REPLACE(tag, '>', '.'), 1)))
),

MostFrequentTags AS (
    SELECT 
        TagName,
        Frequency,
        ROW_NUMBER() OVER (ORDER BY Frequency DESC) AS Rank
    FROM TagFrequency
),

UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(V.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(CASE WHEN PH.Id IS NOT NULL THEN 1 ELSE 0 END) AS EditCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (2, 3)  
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY U.Id, U.DisplayName
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalBounties,
        CommentCount,
        EditCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, TotalBounties DESC) AS UserRank
    FROM UserActivity
)

SELECT 
    T.TagName,
    T.Frequency AS TagFrequency,
    U.DisplayName AS TopUser,
    U.PostCount,
    U.TotalBounties,
    U.CommentCount,
    U.EditCount
FROM MostFrequentTags T
JOIN TopUsers U ON U.UserRank <= 5  
WHERE T.Frequency > 10  
ORDER BY T.Frequency DESC, U.TotalBounties DESC;
