WITH 
UserDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
PostDetail AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreatedDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS PostTags
    FROM 
        Posts P
    LEFT JOIN 
        Tags T ON P.Tags LIKE '%' || T.TagName || '%'
    WHERE 
        P.CreationDate >= DATEADD(MONTH, -1, GETDATE()) 
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreatedDate, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount
),
PostVoting AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId = 6 THEN 1 END) AS CloseVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    UD.DisplayName,
    UD.TotalPosts,
    UD.TotalQuestions,
    UD.TotalAnswers,
    UD.TotalScore,
    UD.LastPostDate,
    PD.Title,
    PD.Score AS PostScore,
    PD.ViewCount,
    PD.AnswerCount,
    PD.CommentCount,
    PD.PostTags,
    PV.UpVotes,
    PV.DownVotes,
    PV.CloseVotes
FROM 
    UserDetails UD
JOIN 
    PostDetail PD ON UD.UserId = PD.OwnerUserId
LEFT JOIN 
    PostVoting PV ON PD.PostId = PV.PostId
ORDER BY 
    UD.Reputation DESC, UD.TotalPosts DESC;
