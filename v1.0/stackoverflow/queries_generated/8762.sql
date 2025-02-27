WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(PH.Comment, 'No comments') AS LastActionComment,
        PH.CreationDate AS LastActionDate,
        PH.PostHistoryTypeId,
        U.DisplayName AS LastEditor
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Users U ON PH.UserId = U.Id
    WHERE 
        P.LastActivityDate >= (NOW() - INTERVAL '30 days')
),
AggregateData AS (
    SELECT 
        UserId,
        SUM(TotalPosts) AS TotalUserPosts,
        SUM(TotalQuestions) AS TotalUserQuestions,
        SUM(TotalAnswers) AS TotalUserAnswers,
        SUM(TotalUpvotes) AS TotalUserUpvotes,
        SUM(TotalDownvotes) AS TotalUserDownvotes
    FROM 
        UserStats
    GROUP BY 
        UserId
)

SELECT 
    U.DisplayName,
    AS.TotalUserPosts,
    AS.TotalUserQuestions,
    AS.TotalUserAnswers,
    AS.TotalUserUpvotes,
    AS.TotalUserDownvotes,
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.ViewCount,
    PD.Score,
    PD.LastActionComment,
    PD.LastActionDate,
    PD.LastEditor
FROM 
    AggregateData AS
JOIN 
    Users U ON AS.UserId = U.Id
JOIN 
    PostDetails PD ON U.Id = PD.LastEditor
WHERE 
    AS.TotalUserPosts > 10
ORDER BY 
    AS.TotalUserUpvotes DESC, 
    PD.ViewCount DESC
LIMIT 100;
