WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(*) AS TagUsage
    FROM 
        Posts P
    CROSS JOIN LATERAL unnest(string_to_array(P.Tags, '>')) AS T(TagName)
    GROUP BY 
        T.TagName
    ORDER BY 
        TagUsage DESC
    LIMIT 5
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER(PARTITION BY P.PostTypeId ORDER BY P.CreationDate DESC) AS RecentActivities,
        STRING_AGG(CASE WHEN C.Text IS NOT NULL THEN C.Text ELSE 'No Comments' END, '; ') AS CommentsText,
        COALESCE(MAX(PH.CreationDate), 'No History') AS LastHistoryDate
    FROM 
        Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
    HAVING 
        COUNT(DISTINCT C.Id) > 3
)
SELECT 
    UA.DisplayName,
    UA.Reputation,
    UA.Views,
    UA.AnswerCount,
    UA.QuestionCount,
    UA.UpVotes - UA.DownVotes AS NetVotes,
    PT.TagName,
    PS.Title,
    PS.ViewCount,
    PS.Score,
    PS.CommentsText,
    PS.LastHistoryDate
FROM 
    UserActivity UA
INNER JOIN PostStatistics PS ON UA.UserId = PS.ViewCount
LEFT JOIN PopularTags PT ON PS.RecentActivities < 3
WHERE 
    UA.BadgeCount > 0
ORDER BY 
    UA.Reputation DESC, PS.ViewCount DESC;

This query combines complex SQL constructs including Common Table Expressions (CTEs) for user activity, popular tags, and post statistics, while also leveraging window functions, correlated subqueries, and string manipulation. The use of conditions, grouping, and joins showcases an intricate relationship between different elements of the schema. The query also illustrates edge cases with NULL handling and unusual predicates.

