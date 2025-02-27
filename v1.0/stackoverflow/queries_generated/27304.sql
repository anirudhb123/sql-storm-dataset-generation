WITH TagCounts AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        AVG(U.Reputation) AS AverageReputation
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
PostEditHistory AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY PH.PostId
)
SELECT 
    TC.TagName,
    TC.PostCount,
    TC.TotalViews,
    TC.AverageScore,
    UR.DisplayName AS UserName,
    UR.TotalUpVotes,
    UR.TotalDownVotes,
    UR.TotalPosts,
    UR.AverageReputation,
    PE.EditCount,
    PE.LastEditDate
FROM TagCounts TC
JOIN UserReputation UR ON UR.TotalPosts > 0
JOIN PostEditHistory PE ON PE.PostId IN (
    SELECT P.Id 
    FROM Posts P 
    WHERE P.Tags LIKE '%' || TC.TagName || '%'
)
WHERE TC.PostCount > 0
ORDER BY TC.PostCount DESC, TC.TotalViews DESC;
