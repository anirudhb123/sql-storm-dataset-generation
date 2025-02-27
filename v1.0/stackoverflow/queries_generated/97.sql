WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN V.VoteTypeId = 6 THEN 1 ELSE 0 END) AS CloseVotes,
        SUM(CASE WHEN V.VoteTypeId = 16 THEN 1 ELSE 0 END) AS ApproveEditVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
HighScoredUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        Upvotes, 
        Downvotes, 
        CloseVotes, 
        ApproveEditVotes,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserScores
    WHERE 
        Reputation > 5000
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        Upvotes,
        Downvotes,
        CloseVotes,
        ApproveEditVotes,
        Rank
    FROM 
        HighScoredUsers
    WHERE 
        Rank <= 10
)
SELECT 
    U.DisplayName AS TopUser,
    U.Reputation,
    COALESCE(UPV.Upvotes, 0) AS UpvoteCount,
    COALESCE(DOV.Downvotes, 0) AS DownvoteCount,
    COALESCE(CLV.CloseVotes, 0) AS CloseVoteCount,
    COALESCE(EDV.ApproveEditVotes, 0) AS EditApprovalCount,
    STRING_AGG(DISTINCT T.TagName, ', ') AS AssociatedTags
FROM 
    TopUsers U
LEFT JOIN 
    Posts P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Tags T ON T.Id IN (SELECT UNNEST(string_to_array(P.Tags, ','))::int)
LEFT JOIN 
    (SELECT UserId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes FROM Votes GROUP BY UserId) UPV ON UPV.UserId = U.UserId
LEFT JOIN 
    (SELECT UserId, SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes FROM Votes GROUP BY UserId) DOV ON DOV.UserId = U.UserId
LEFT JOIN 
    (SELECT UserId, SUM(CASE WHEN VoteTypeId = 6 THEN 1 ELSE 0 END) AS CloseVotes FROM Votes GROUP BY UserId) CLV ON CLV.UserId = U.UserId
LEFT JOIN 
    (SELECT UserId, SUM(CASE WHEN VoteTypeId = 16 THEN 1 ELSE 0 END) AS ApproveEditVotes FROM Votes GROUP BY UserId) EDV ON EDV.UserId = U.UserId
GROUP BY 
    U.DisplayName, U.Reputation, U.UserId
ORDER BY 
    U.Reputation DESC;
