-- Performance Benchmarking Query for Stack Overflow Schema

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(CASE WHEN P.UpVotes IS NOT NULL THEN P.UpVotes ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN P.DownVotes IS NOT NULL THEN P.DownVotes ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistories AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS HistoryCount,
        MAX(PH.CreationDate) AS LastEditedDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.TotalPosts,
    US.QuestionsCount,
    US.AnswersCount,
    US.TotalUpVotes,
    US.TotalDownVotes,
    PH.HistoryCount,
    PH.LastEditedDate
FROM 
    UserStats US
LEFT JOIN 
    PostHistories PH ON US.TotalPosts > 0 AND PH.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = US.UserId)
ORDER BY 
    US.TotalPosts DESC, US.TotalUpVotes DESC;
