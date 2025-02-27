WITH RecursiveUserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        V.VoteTypeId,
        COUNT(V.Id) AS TotalVotes,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY COUNT(V.Id) DESC) AS VoteRank
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, V.VoteTypeId
),
UserVoteSummary AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN V.TotalVotes ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN V.TotalVotes ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM RecursiveUserVotes U
    LEFT JOIN Posts P ON U.UserId = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.UserId, U.DisplayName
),
LatestPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
)
SELECT 
    U.DisplayName,
    U.UpVotes, 
    U.DownVotes,
    (U.UpVotes - U.DownVotes) AS VoteBalance,
    LP.Title AS RecentPostTitle,
    LP.CreationDate AS RecentPostCreationDate,
    CASE 
        WHEN LP.PostId IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS HasRecentPost
FROM UserVoteSummary U
LEFT JOIN LatestPosts LP ON U.UserId = LP.OwnerUserId AND LP.RecentPostRank = 1
WHERE (U.UpVotes > 5 OR U.DownVotes > 5)
ORDER BY VoteBalance DESC, U.DisplayName;
