WITH TagStatistics AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM Posts
    WHERE PostTypeId = 1
    GROUP BY TagName
), UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.PostTypeId = 1 -- focus on questions only
    GROUP BY U.Id, U.DisplayName
), PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        PT.Name AS PostType,
        User.DisplayName AS OwnerName,
        COALESCE(UC.TagCount, 0) AS TagCount,
        COALESCE(US.TotalViews, 0) AS UserTotalViews
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
    JOIN Users User ON P.OwnerUserId = User.Id
    LEFT JOIN (SELECT 
        PostId, COUNT(*) AS TagCount 
        FROM PostLinks 
        GROUP BY PostId) UC ON P.Id = UC.PostId
    LEFT JOIN UserActivity US ON US.UserId = P.OwnerUserId
    WHERE P.CreationDate > CURRENT_DATE - INTERVAL '30 days' -- limit by time frame
)
SELECT 
    TS.TagName,
    COUNT(DISTINCT PD.PostId) AS PostsWithTag,
    SUM(PD.ViewCount) AS TotalViewsForTag,
    AVG(PD.UserTotalViews) AS AvgUserViewsPerPost,
    SUM(PD.TagCount) AS TotalTagsUsed
FROM TagStatistics TS
JOIN PostDetails PD ON PD.Title ILIKE '%' || TS.TagName || '%'
GROUP BY TS.TagName
ORDER BY PostsWithTag DESC, TotalViewsForTag DESC
LIMIT 10;
