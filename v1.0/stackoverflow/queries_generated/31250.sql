WITH RECURSIVE UserVoteHistory AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        V.PostId, 
        V.VoteTypeId,
        V.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY V.CreationDate DESC) AS VoteRank
    FROM 
        Users U
    JOIN 
        Votes V ON U.Id = V.UserId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        RANK() OVER (ORDER BY SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(CMT.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedCount,
        AVG(UP.Reputation) AS AvgUserReputation
    FROM 
        Posts P
    LEFT JOIN 
        Comments CMT ON P.Id = CMT.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Users UP ON P.OwnerUserId = UP.Id
    GROUP BY 
        P.Id
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Upvotes,
    TU.Downvotes,
    PS.PostId,
    PS.Title,
    PS.CommentCount,
    PS.UpvoteCount,
    PS.DownvoteCount,
    PS.ClosedCount,
    PS.AvgUserReputation
FROM 
    TopUsers TU
JOIN 
    PostStats PS ON PS.UpvoteCount > 10 -- Join on posts that have more than 10 upvotes
WHERE 
    TU.UserRank <= 10 -- Limiting to top 10 users
ORDER BY 
    TU.Upvotes DESC, 
    PS.UpvoteCount DESC;

-- This query pulls detailed statistics regarding top users who have shown high activity in terms of voting, 
-- while also providing insights into the performance of posts based on their interaction metrics.
