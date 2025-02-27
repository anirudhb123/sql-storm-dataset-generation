WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS QuestionsAsked,
        COUNT(DISTINCT A.Id) AS AnswersProvided,
        SUM(COALESCE(V.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(V.DownVotes, 0)) AS TotalDownVotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1  -- Questions
    LEFT JOIN Posts A ON U.Id = A.OwnerUserId AND A.PostTypeId = 2  -- Answers
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
HighScoringQuestions AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName
    FROM 
        Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 AND P.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1)
),
RecentActivity AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN C.CreationDate > NOW() - INTERVAL '30 days' THEN 1 END) AS RecentComments,
        COUNT(CASE WHEN PH.CreationDate > NOW() - INTERVAL '30 days' THEN 1 END) AS RecentPostEdits
    FROM 
        Users U
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN PostHistory PH ON U.Id = PH.UserId
    GROUP BY U.Id
),
UserPerformance AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.QuestionsAsked,
        UA.AnswersProvided,
        UA.TotalUpVotes,
        UA.TotalDownVotes,
        COALESCE(RA.RecentComments, 0) AS RecentComments,
        COALESCE(RA.RecentPostEdits, 0) AS RecentPostEdits,
        H.QScore
    FROM 
        UserActivity UA
    LEFT JOIN RecentActivity RA ON UA.UserId = RA.UserId
    LEFT JOIN (
        SELECT 
            P.OwnerUserId,
            SUM(P.Score) AS QScore
        FROM 
            HighScoringQuestions P
        GROUP BY P.OwnerUserId
    ) H ON UA.UserId = H.OwnerUserId
)
SELECT 
    UP.DisplayName,
    UP.QuestionsAsked,
    UP.AnswersProvided,
    UP.TotalUpVotes,
    UP.TotalDownVotes,
    UP.RecentComments,
    UP.RecentPostEdits,
    UP.QScore,
    R.UserRank
FROM 
    UserPerformance UP
JOIN UserActivity R ON UP.UserId = R.UserId
ORDER BY 
    UP.TotalUpVotes DESC,
    UP.QuestionsAsked DESC;
