WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedQuestions
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CM.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY V.CreationDate DESC) AS VoteRank,
        COALESCE(CAST(PH.Comment AS INT), 0) AS CloseReason
    FROM 
        Posts P
    LEFT JOIN 
        Comments CM ON P.Id = CM.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId = 10
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, PH.Comment
),
PopularQuestions AS (
    SELECT
        PD.PostId,
        PD.Title,
        PD.Score,
        PD.ViewCount,
        US.DisplayName,
        US.Reputation,
        DENSE_RANK() OVER (ORDER BY PD.Score DESC) AS Rank
    FROM 
        PostDetails PD
    JOIN 
        UserStats US ON PD.PostId IN (US.UserId) 
    WHERE 
        PD.CloseReason IS NULL AND 
        PD.ViewCount > 100
)
SELECT 
    PQ.Rank,
    PQ.Title,
    PQ.Score,
    PQ.ViewCount,
    PQ.DisplayName,
    PQ.Reputation
FROM 
    PopularQuestions PQ
WHERE 
    PQ.Rank <= 10
ORDER BY 
    PQ.Score DESC;
