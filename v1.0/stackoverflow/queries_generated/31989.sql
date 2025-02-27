WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN PT.Name = 'Question' THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PT.Name = 'Answer' THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN C.PostId IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT PH.Comment, '; ') AS EditComments
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 24, 33)  -- Edit Title, Edit Body, Suggested Edit Applied, Post Notice Added
    GROUP BY 
        PH.PostId
)
SELECT 
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.TotalComments,
    UPS.TotalUpVotes,
    UPS.TotalDownVotes,
    COALESCE(PHS.EditCount, 0) AS EditCount,
    COALESCE(PHS.LastEditDate, 'No Edits') AS LastEditDate,
    COALESCE(PHS.EditComments, 'No Comments') AS EditComments
FROM 
    UserPostStats UPS
LEFT JOIN 
    PostHistoryStats PHS ON UPS.UserId = (SELECT OwnerUserId FROM Posts WHERE Id IN (SELECT PostId FROM PostHistory WHERE Id IN (SELECT MAX(Id) FROM PostHistory GROUP BY PostId)))
WHERE 
    UPS.Reputation > 1000  -- Filtering users with reputation greater than 1000
ORDER BY 
    UPS.TotalPosts DESC, UPS.TotalUpVotes DESC;  -- Ordering by total posts and total upvotes

