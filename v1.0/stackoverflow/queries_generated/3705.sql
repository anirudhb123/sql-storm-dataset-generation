WITH RankedUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN U.Reputation IS NULL THEN 'Unknown' ELSE 'Known' END ORDER BY U.Reputation DESC) as ReputationRank
    FROM Users U
),
TopPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AcceptedAnswerId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount,
        P.CreationDate,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC) as PostRank
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY P.Id
),
PostStats AS (
    SELECT 
        TP.Id AS PostId,
        TP.Title,
        TP.Score,
        TP.ViewCount,
        COALESCE(AU.DisplayName, 'Community User') AS AcceptedAnswerUser,
        R.Reputation AS TopUserReputation,
        TP.UpvoteCount,
        TP.DownvoteCount,
        CASE 
            WHEN TP.Score > 0 THEN 'Positive' 
            WHEN TP.Score < 0 THEN 'Negative' 
            ELSE 'Neutral' 
        END AS ScoreCategory
    FROM TopPosts TP
    LEFT JOIN Posts A ON TP.AcceptedAnswerId = A.Id
    LEFT JOIN RankedUsers R ON TP.Score >= R.Reputation
)
SELECT 
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.AcceptedAnswerUser,
    PS.UpvoteCount,
    PS.DownvoteCount,
    PS.ScoreCategory,
    CASE 
        WHEN PS.TopUserReputation IS NOT NULL THEN 'User Found'
        ELSE 'User Not Found'
    END AS UserStatus,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = PS.PostId) AS CommentCount,
    (SELECT STRING_AGG(T.Tags, ', ') 
     FROM (
         SELECT DISTINCT SUBSTRING(tag, 2, LENGTH(tag) - 2) AS Tags
         FROM UNNEST(STRING_TO_ARRAY(PS.Title, ' ')) AS tag
         WHERE tag LIKE '#%'
     ) T) AS RelatedTags
FROM PostStats PS
WHERE PS.PostId IN (SELECT PostId FROM PostHistory WHERE PostHistoryTypeId IN (10, 11))
ORDER BY PS.Score DESC
LIMIT 20;
