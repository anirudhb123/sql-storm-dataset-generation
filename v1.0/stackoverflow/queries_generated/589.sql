WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM Posts P
    GROUP BY P.OwnerUserId
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
VoteSummary AS (
    SELECT 
        V.UserId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes V
    GROUP BY V.UserId
)
SELECT 
    UR.UserId,
    UR.DisplayName,
    COALESCE(PS.QuestionCount, 0) AS QuestionCount,
    COALESCE(PS.AnswerCount, 0) AS AnswerCount,
    COALESCE(VS.UpVotes, 0) AS UpVotes,
    COALESCE(VS.DownVotes, 0) AS DownVotes,
    UR.Reputation AS Reputation,
    P.TagName,
    P.PostCount,
    RANK() OVER (ORDER BY UR.Reputation DESC) AS UserRank
FROM UserReputation UR
LEFT JOIN PostStats PS ON UR.UserId = PS.OwnerUserId
LEFT JOIN VoteSummary VS ON UR.UserId = VS.UserId
LEFT JOIN PopularTags P ON P.TagName IN (
    SELECT 
        UNNEST(STRING_TO_ARRAY((SELECT STRING_AGG(T.TagName, ',') FROM Tags T), ','))
)
ORDER BY UserRank, UR.DisplayName;
