
WITH TagFrequency AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(tag, '>', 1)) AS TagName,
        COUNT(*) AS Frequency
    FROM (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS tag
        FROM Posts
        JOIN (
            SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
            UNION ALL SELECT 9 UNION ALL SELECT 10
        ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
        WHERE PostTypeId = 1
    ) AS TagList
    GROUP BY TagName
),

MostFrequentTags AS (
    SELECT 
        TagName,
        Frequency,
        @rank := @rank + 1 AS Rank
    FROM TagFrequency, (SELECT @rank := 0) AS r
    ORDER BY Frequency DESC
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
        @user_rank := @user_rank + 1 AS UserRank
    FROM UserActivity, (SELECT @user_rank := 0) AS ur
    ORDER BY PostCount DESC, TotalBounties DESC
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
