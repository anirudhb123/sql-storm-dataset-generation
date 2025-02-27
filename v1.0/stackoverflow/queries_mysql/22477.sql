
WITH RecursiveAggregatedVotes AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS UpVotes,
        COUNT(V.Id) AS DownVotes,
        COUNT(V.Id) AS TotalVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY COUNT(V.Id) DESC) AS VoteRank
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
    GROUP BY P.Id, P.OwnerUserId
),

FilteredPosts AS (
    SELECT 
        P.Id, 
        P.Title, 
        P.ViewCount, 
        P.Score, 
        R.UpVotes, 
        R.DownVotes, 
        R.TotalVotes,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount
    FROM Posts P
    JOIN RecursiveAggregatedVotes R ON P.Id = R.PostId
    WHERE R.UpVotes > R.DownVotes
    AND P.CreationDate < '2024-10-01 12:34:56' - INTERVAL 7 DAY
),

TagPostCount AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
)

SELECT 
    FP.Title, 
    FP.ViewCount, 
    FP.Score, 
    FP.UpVotes, 
    FP.DownVotes, 
    FP.CommentCount,
    COALESCE(TPC.PostCount, 0) AS RelatedPosts,
    CASE 
        WHEN FP.Score >= 10 THEN 'Highly Engaged'
        WHEN FP.Score BETWEEN 5 AND 9 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementStatus
FROM FilteredPosts FP
LEFT JOIN TagPostCount TPC ON FP.Title LIKE CONCAT('%', TPC.TagName, '%') 
WHERE FP.CommentCount > 0
ORDER BY FP.ViewCount DESC, FP.Score DESC
LIMIT 100;
