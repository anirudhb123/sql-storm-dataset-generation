WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2), 0) AS Upvotes,
        COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3), 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE
        P.PostTypeId = 1 -- Only questions
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalQuestions,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(P.CommentCount, 0)) AS TotalComments,
        SUM(RP.Upvotes) AS TotalUpvotes,
        SUM(RP.Downvotes) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        RankedPosts RP ON U.Id = RP.OwnerUserId
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.TotalQuestions,
        U.TotalViews,
        U.TotalAnswers,
        U.TotalComments,
        U.TotalUpvotes,
        U.TotalDownvotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC, U.TotalUpvotes DESC) AS UserRank
    FROM 
        UserStats U
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.TotalQuestions,
    TU.TotalViews,
    TU.TotalAnswers,
    TU.TotalComments,
    TU.TotalUpvotes,
    TU.TotalDownvotes
FROM 
    TopUsers TU
WHERE
    TU.UserRank <= 10 -- Top 10 users by reputation and upvotes
ORDER BY 
    TU.UserRank;
