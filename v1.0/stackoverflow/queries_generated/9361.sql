WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty,
        AVG(DATEDIFF(second, U.CreationDate, GETDATE())) / 86400.0 AS AverageAccountAgeDays
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN 
        Votes V ON U.Id = V.UserId AND V.VoteTypeId = 8
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.UpVotes, U.DownVotes
),
PostRanking AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS Owner,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        PR.PostId, 
        PR.Title, 
        PR.Owner, 
        COALESCE(PS.CommentCount, 0) AS CommentCount, 
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY PR.Score DESC) AS Rank
    FROM 
        PostRanking PR
    LEFT JOIN 
        Posts PS ON PR.PostId = PS.Id
)
SELECT 
    US.DisplayName,
    US.Reputation,
    US.QuestionCount,
    US.AcceptedAnswers,
    US.TotalBounty,
    T.Titles AS TopPosts,
    T.CommentCount,
    T.AnswerCount,
    US.AverageAccountAgeDays
FROM 
    UserStats US
LEFT JOIN 
    (SELECT 
         Owner, 
         STRING_AGG(Title, ', ') AS Titles 
     FROM 
         TopPosts 
     WHERE 
         Rank <= 5 
     GROUP BY 
         Owner) T ON US.DisplayName = T.Owner
ORDER BY 
    US.Reputation DESC, 
    US.QuestionCount DESC;
