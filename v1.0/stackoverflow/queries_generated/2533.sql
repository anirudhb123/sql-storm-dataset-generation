WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        RANK() OVER (ORDER BY SUM(COALESCE(P.Score, 0)) DESC) AS ScoreRank
    FROM 
        Users U
        LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, DisplayName, TotalPosts, TotalScore, AvgViewCount, QuestionCount, AnswerCount
    FROM 
        UserPostStats
    WHERE 
        ScoreRank <= 10
),
PostMetrics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS TotalComments,
        SUM(COALESCE(V.VoteTypeId = 2, 0)::int) AS TotalUpVotes,
        SUM(COALESCE(V.VoteTypeId = 3, 0)::int) AS TotalDownVotes
    FROM 
        Posts P
        LEFT JOIN Comments C ON P.Id = C.PostId
        LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title
)
SELECT
    U.UserId,
    U.DisplayName,
    U.TotalPosts,
    U.TotalScore,
    U.AvgViewCount,
    P.PostId,
    P.Title,
    P.TotalComments,
    P.TotalUpVotes,
    P.TotalDownVotes,
    CASE 
        WHEN P.TotalUpVotes IS NULL THEN 'No Votes'
        ELSE CASE 
            WHEN P.TotalUpVotes > P.TotalDownVotes THEN 'More Upvotes'
            WHEN P.TotalUpVotes < P.TotalDownVotes THEN 'More Downvotes'
            ELSE 'Equal Votes'
        END
    END AS VoteStatus,
    (CASE 
        WHEN P.TotalUpVotes IS NOT NULL THEN 
            (P.TotalUpVotes::decimal / NULLIF((P.TotalUpVotes + P.TotalDownVotes), 0)) * 100 
        ELSE 0 END) AS VotePercentage
FROM 
    TopUsers U
    LEFT JOIN PostMetrics P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.TotalScore DESC, 
    P.TotalComments DESC
LIMIT 50;
