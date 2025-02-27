WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
), 
PostAnalysis AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE((
            SELECT COUNT(*)
            FROM Comments C
            WHERE C.PostId = P.Id
        ), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.ParentId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        P.*,
        U.DisplayName AS OwnerName,
        CASE 
            WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer
    FROM 
        PostAnalysis P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.Rank = 1
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.TotalAnswers,
    US.TotalQuestions,
    US.UpVotes,
    US.DownVotes,
    TP.Title AS TopPostTitle,
    TP.CreationDate AS TopPostCreationDate,
    TP.Score AS TopPostScore,
    TP.ViewCount AS TopPostViewCount,
    TP.CommentCount AS TopPostCommentCount,
    TP.HasAcceptedAnswer
FROM 
    UserStats US
LEFT JOIN 
    TopPosts TP ON US.UserId = TP.OwnerUserId
WHERE 
    US.Reputation > 1000 
    AND (
        TP.Score IS NULL OR TP.ViewCount > 100
    )
ORDER BY 
    US.Reputation DESC, 
    COALESCE(TP.Score, 0) DESC
FETCH FIRST 10 ROWS ONLY;

This SQL query performs several advanced constructs to gather statistics on users and their posts, demonstrating the use of Common Table Expressions (CTEs), window functions (ROW_NUMBER), conditional aggregation, and various join types. It selects users with a reputation greater than 1000 who have the top posts in the last year, factoring in multiple aggregate calculations and handling NULLs in a coherent way.
