WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.DisplayName,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
    HAVING COUNT(P.Id) > 10
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.CreationDate AS ClosedDate,
        PH.UserDisplayName AS ClosedBy
    FROM Posts P
    JOIN PostHistory PH ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId = 10
    ORDER BY PH.CreationDate DESC
),
RecentVotes AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes V
    GROUP BY V.PostId
),
PostStatistics AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        COALESCE(RV.UpVotes, 0) AS TotalUpVotes,
        COALESCE(RV.DownVotes, 0) AS TotalDownVotes,
        COALESCE(CP.ClosedDate, NULL) AS ClosedPostDate,
        COALESCE(CP.ClosedBy, 'Open') AS ClosedBy
    FROM Posts P
    LEFT JOIN RecentVotes RV ON P.Id = RV.PostId
    LEFT JOIN ClosedPosts CP ON P.Id = CP.PostId
)
SELECT 
    PS.Id AS PostId,
    PS.Title,
    PS.CreationDate,
    PS.TotalUpVotes,
    PS.TotalDownVotes,
    PS.ClosedPostDate,
    PS.ClosedBy,
    UT.UserId,
    UT.DisplayName,
    PT.TagName
FROM PostStatistics PS
CROSS JOIN UserReputation UT
JOIN PopularTags PT ON PS.Title ILIKE '%' || PT.TagName || '%'
WHERE PS.ClosedPostDate IS NULL
ORDER BY UT.Rank, PS.TotalUpVotes DESC
LIMIT 100;
