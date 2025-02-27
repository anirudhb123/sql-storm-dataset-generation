WITH RecursiveUserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.Reputation DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.Views, U.UpVotes, U.DownVotes
), 
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.CommentCount,
        P.AnswerCount,
        PH.UserDisplayName AS LastEditor,
        PH.CreationDate AS LastEditDate,
        RANK() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS EditionRank
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= '2023-01-01'
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    COALESCE(PA.PostId, -1) AS LatestPostId,
    COALESCE(PA.Title, 'No Posts Available') AS LatestPostTitle,
    COALESCE(PA.LastEditor, 'N/A') AS LastEditedBy,
    COALESCE(PA.LastEditDate, 'Never Edited') AS LastEditDate,
    CASE 
        WHEN U.Reputation > 1000 THEN 'High Repute'
        WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Moderate Repute'
        ELSE 'Low Repute' 
    END AS ReputationCategory
FROM 
    RecursiveUserScore U
LEFT JOIN 
    PostActivity PA ON U.UserId = PA.PostId AND PA.EditionRank = 1
WHERE 
    U.TotalPosts > 5
ORDER BY 
    U.Reputation DESC;
