WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT V.PostId) AS TotalVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 8 THEN V.BountyAmount ELSE 0 END), 0) AS TotalBounty
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),

PostAggregate AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.PostTypeId,
        P.OwnerUserId,
        P.CreationDate,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        MAX(Ph.CreationDate) AS LastEditDate
    FROM Posts P
    LEFT JOIN Comments C ON C.PostId = P.Id
    LEFT JOIN Votes V ON V.PostId = P.Id
    LEFT JOIN PostHistory Ph ON Ph.PostId = P.Id
    GROUP BY P.Id
),

TopPostStatistics AS (
    SELECT 
        PA.PostId,
        PA.Title,
        PA.TotalComments,
        PA.Upvotes,
        PA.Downvotes,
        PA.LastEditDate,
        U.DisplayName AS OwnerName,
        US.Upvotes AS OwnerUpvotes,
        US.Downvotes AS OwnerDownvotes,
        US.TotalVotes AS OwnerTotalVotes,
        US.TotalBounty
    FROM PostAggregate PA
    JOIN Users U ON PA.OwnerUserId = U.Id
    JOIN UserVoteSummary US ON U.Id = US.UserId
    WHERE PA.TotalComments > 0 -- Only considering posts with comments
    ORDER BY PA.Upvotes DESC, PA.Downvotes ASC
    LIMIT 10
)

SELECT 
    T.*,
    CASE 
        WHEN LastEditDate IS NOT NULL THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus,
    (CASE 
        WHEN Upvotes > Downvotes THEN 'Most Positive'
        WHEN Upvotes < Downvotes THEN 'Mostly Negative'
        ELSE 'Neutral'
    END) AS SentimentStatus,
    CASE 
        WHEN TotalBounty > 0 THEN 'Has Bounty'
        ELSE 'No Bounty'
    END AS BountyStatus
FROM TopPostStatistics T
LEFT JOIN TagTable TT ON TT.ExcerptPostId = T.PostId -- Assuming TagTable exists for relationships
WHERE UPPER(T.OwnerName) LIKE 'A%' -- Filtering owner's names starting with 'A'
AND T.OwnerTotalVotes > 10 -- Only for active voters
ORDER BY T.Upvotes DESC, T.Downvotes ASC;
