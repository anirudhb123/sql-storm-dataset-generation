WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY T.TagName
    HAVING COUNT(P.Id) > 10
),
HighScorers AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS ScoringRank
    FROM Posts P
    WHERE P.PostTypeId = 1
)
SELECT 
    UA.DisplayName AS UserName,
    UA.PostCount AS TotalPosts,
    UA.UpVotes - UA.DownVotes AS NetVotes,
    STUFF((SELECT ',' + PT.TagName FROM PopularTags PT WHERE PT.PostCount > 10 FOR XML PATH('')), 1, 1, '') AS PopularTags,
    (SELECT COUNT(*) FROM HighScorers HS WHERE HS.ScoringRank = 1 AND HS.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = UA.UserId)) AS HighScorerCount
FROM UserActivity UA
WHERE UA.UserRank <= 10
ORDER BY UA.NetVotes DESC;
