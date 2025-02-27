WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId IN (1, 6, 7) THEN 1 ELSE 0 END) AS AcceptedOrCloseOrReopenVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(PH.Id) AS HistoryCount,
        MIN(PH.CreationDate) AS FirstEditDate
    FROM PostHistory PH
    WHERE PH.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY PH.PostId, PH.PostHistoryTypeId
),
RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.AnswerCount,
        P.ViewCount,
        P.CreationDate,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
      AND P.PostTypeId = 1 -- Questions only
      AND P.AnswerCount > 0
),
ModeratedPostHistory AS (
    SELECT 
        P.Id AS PostId,
        PH.PostHistoryTypeId,
        PH.UserDisplayName,
        PH.CreationDate,
        PH.Comment
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE PH.PostHistoryTypeId IN (10, 11) 
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.AnswerCount,
    RP.ViewCount,
    USP.DisplayName AS TopVoter,
    UVote.TotalVotes,
    UVote.UpVotes,
    UVote.DownVotes,
    COALESCE(MAX(MPH.UserDisplayName) FILTER (WHERE MPH.PostHistoryTypeId = 10), 'Not Closed') AS LastClosedBy,
    COALESCE(MAX(MPH.CreationDate) FILTER (WHERE MPH.PostHistoryTypeId = 10), 'No Close Date') AS LastClosedDate,
    PH.HistoryCount,
    PH.FirstEditDate
FROM RankedPosts RP
LEFT JOIN UserVoteStats UVote ON UVote.UserId = (SELECT UserId FROM Votes WHERE PostId = RP.PostId ORDER BY CreationDate LIMIT 1)
LEFT JOIN PostHistoryStats PH ON PH.PostId = RP.PostId
LEFT JOIN ModeratedPostHistory MPH ON MPH.PostId = RP.PostId  
WHERE RP.Rank <= 10 
GROUP BY RP.PostId, RP.Title, RP.Score, RP.AnswerCount, RP.ViewCount, USP.DisplayName, UVote.TotalVotes, UVote.UpVotes, UVote.DownVotes, PH.HistoryCount, PH.FirstEditDate
ORDER BY RP.Score DESC, RP.CreationDate DESC;
