WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        ROUND(COALESCE(SUM(P.Score) / NULLIF(COUNT(P.Id), 0), 0), 2) AS AveragePostScore
    FROM 
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(P.Id) DESC) AS TagRank
    FROM 
        Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
),
HighScoringPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        U.DisplayName AS Owner,
        NTILE(3) OVER (ORDER BY P.Score DESC) AS ScoreTier
    FROM 
        Posts P
    INNER JOIN Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.Score > 0
),
RecentVotes AS (
    SELECT 
        PostId,
        COUNT(V.Id) AS VoteCount
    FROM 
        Votes V
    WHERE 
        V.CreationDate > NOW() - INTERVAL '30 days'
    GROUP BY V.PostId
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) , 0) AS CloseReopenCount,
        COALESCE(RV.VoteCount, 0) AS RecentVoteCount
    FROM 
        Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN RecentVotes RV ON P.Id = RV.PostId
    GROUP BY P.Id, P.Title
)
SELECT 
    U.DisplayName,
    U.PostCount,
    U.UpVoteCount,
    U.DownVoteCount,
    U.AveragePostScore,
    PT.TagName,
    PT.PostCount AS TagPostCount,
    HSP.Title AS HighScoringPost,
    HSP.Score AS HighScoringPostScore,
    PM.CloseReopenCount,
    PM.RecentVoteCount
FROM 
    UserStatistics U
LEFT JOIN PopularTags PT ON U.PostCount >= 5
LEFT JOIN HighScoringPosts HSP ON U.UserId = HSP.Owner
LEFT JOIN PostMetrics PM ON HSP.PostId = PM.PostId
WHERE 
    U.AveragePostScore > 10 AND 
    (HSP.ScoreTier = 1 OR PM.RecentVoteCount > 0)
ORDER BY 
    U.AveragePostScore DESC, 
    PM.CloseReopenCount DESC, 
    U.DisplayName ASC;
