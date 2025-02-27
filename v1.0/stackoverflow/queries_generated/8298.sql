WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostHistories AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        COUNT(CASE WHEN PHT.Name = 'Post Closed' THEN 1 END) AS ClosedPosts,
        COUNT(CASE WHEN PHT.Name = 'Post Reopened' THEN 1 END) AS ReopenedPosts,
        COUNT(CASE WHEN PHT.Name = 'Edit Body' THEN 1 END) AS BodyEdits
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.UserId, PH.PostId
),
UserPostHistory AS (
    SELECT 
        U.DisplayName,
        US.TotalPosts,
        US.TotalComments,
        US.TotalUpVotes,
        US.TotalDownVotes,
        PH.ClosedPosts,
        PH.ReopenedPosts,
        PH.BodyEdits
    FROM 
        UserStats US
    LEFT JOIN 
        PostHistories PH ON US.UserId = PH.UserId
)

SELECT 
    DisplayName,
    TotalPosts,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes,
    COALESCE(SUM(ClosedPosts), 0) AS TotalClosedPosts,
    COALESCE(SUM(ReopenedPosts), 0) AS TotalReopenedPosts,
    COALESCE(SUM(BodyEdits), 0) AS TotalBodyEdits
FROM 
    UserPostHistory
GROUP BY 
    DisplayName, TotalPosts, TotalComments, TotalUpVotes, TotalDownVotes
ORDER BY 
    TotalUpVotes DESC, TotalPosts DESC
LIMIT 10;
