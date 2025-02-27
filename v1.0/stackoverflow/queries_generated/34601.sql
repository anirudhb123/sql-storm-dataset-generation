WITH RecursivePostCTE AS (
    -- Recursive CTE to find all answers for each question and their respective scores
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.OwnerUserId,
        1 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 1  -- only questions
    UNION ALL
    SELECT 
        A.Id AS PostId,
        A.Title,
        A.ViewCount,
        A.Score,
        A.AnswerCount,
        A.OwnerUserId,
        R.Level + 1  -- increment level for nested answers
    FROM Posts A
    INNER JOIN RecursivePostCTE R ON A.ParentId = R.PostId  -- linking answers to questions
    WHERE A.PostTypeId = 2  -- only answers
),

UserReputationCTE AS (
    -- Calculate user reputation and badge counts
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),

PostVoteSummary AS (
    -- Summarize post votes
    SELECT 
        P.Id AS PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id
),

FinalResults AS (
    -- Join all collected data
    SELECT 
        R.PostId,
        R.Title,
        R.ViewCount,
        R.Score,
        R.AnswerCount,
        U.DisplayName AS OwnerName,
        U.Reputation AS OwnerReputation,
        U.BadgeCount,
        PVS.UpVotes,
        PVS.DownVotes
    FROM RecursivePostCTE R
    JOIN UserReputationCTE U ON R.OwnerUserId = U.UserId
    LEFT JOIN PostVoteSummary PVS ON R.PostId = PVS.PostId
)

-- Final query to get a benchmarked overview
SELECT 
    PostId,
    Title,
    ViewCount,
    Score,
    AnswerCount,
    OwnerName,
    OwnerReputation,
    BadgeCount,
    UpVotes,
    DownVotes,
    CASE 
        WHEN Score > 100 THEN 'Hot'
        WHEN UpVotes >= DownVotes THEN 'Trending'
        ELSE 'New'
    END AS PostNature
FROM FinalResults
ORDER BY Score DESC, ViewCount DESC
FETCH FIRST 10 ROWS ONLY;  -- limiting results for benchmarking
