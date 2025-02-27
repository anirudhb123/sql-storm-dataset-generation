WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        (SELECT COALESCE(SUM(VoteTypeId = 2), 0) FROM Votes V WHERE V.UserId = U.Id) AS TotalUpVotes,
        (SELECT COALESCE(SUM(VoteTypeId = 3), 0) FROM Votes V WHERE V.UserId = U.Id) AS TotalDownVotes,
        (SELECT COALESCE(COUNT(*), 0) FROM Posts P WHERE P.OwnerUserId = U.Id) AS TotalPosts,
        (SELECT COALESCE(SUM(Score), 0) FROM Posts P WHERE P.OwnerUserId = U.Id) AS TotalPostScore
    FROM Users U
    WHERE U.Reputation > 1000
),
TopVotedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.PostTypeId = 1 -- Questions
    ORDER BY P.Score DESC
    LIMIT 10
),
UserMetrics AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.TotalUpVotes,
        US.TotalDownVotes,
        US.TotalPosts,
        US.TotalPostScore,
        (US.TotalUpVotes - US.TotalDownVotes) AS NetVotes
    FROM UserScore US
)
SELECT 
    UM.DisplayName AS User_DisplayName,
    UM.Reputation AS User_Reputation,
    UM.TotalPosts AS User_TotalPosts,
    UM.TotalPostScore AS User_TotalPostScore,
    UM.NetVotes AS User_NetVotes,
    T.PostId,
    T.Title AS Post_Title,
    T.ViewCount AS Post_ViewCount,
    T.Score AS Post_Score,
    T.AnswerCount AS Post_AnswerCount,
    T.CreationDate AS Post_CreationDate
FROM UserMetrics UM
JOIN TopVotedPosts T ON UM.UserId = T.OwnerUserId
ORDER BY UM.Reputation DESC, T.Score DESC;
