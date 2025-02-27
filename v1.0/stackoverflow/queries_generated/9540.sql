WITH PopularQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS Owner,
        P.ViewCount,
        COUNT(A.Id) AS AnswerCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1  -- Questions
    GROUP BY 
        P.Id, P.Title, P.CreationDate, U.DisplayName, P.ViewCount
    HAVING 
        COUNT(A.Id) > 0 AND P.ViewCount > 1000
),
VoteSummary AS (
    SELECT 
        PostId,
        COUNT(*) FILTER (WHERE VoteTypeId = 2) AS UpVotes,
        COUNT(*) FILTER (WHERE VoteTypeId = 3) AS DownVotes,
        COUNT(*) FILTER (WHERE VoteTypeId IN (10, 11)) AS CloseReopenCount
    FROM 
        Votes 
    GROUP BY 
        PostId
),
TopPosts AS (
    SELECT 
        PQ.PostId,
        PQ.Title,
        PQ.Owner,
        PQ.ViewCount,
        PQ.AnswerCount,
        PQ.UpVotes,
        PQ.DownVotes,
        COALESCE(VS.UpVotes, 0) AS CumulativeUpVotes,
        COALESCE(VS.DownVotes, 0) AS CumulativeDownVotes,
        COALESCE(VS.CloseReopenCount, 0) AS CloseReopenCount
    FROM 
        PopularQuestions PQ
    LEFT JOIN 
        VoteSummary VS ON PQ.PostId = VS.PostId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Owner,
    TP.ViewCount,
    TP.AnswerCount,
    TP.UpVotes + TP.CumulativeUpVotes AS TotalUpVotes,
    TP.DownVotes + TP.CumulativeDownVotes AS TotalDownVotes,
    TP.CloseReopenCount,
    (TP.TotalUpVotes - TP.TotalDownVotes) AS VoteBalance
FROM 
    TopPosts TP
ORDER BY 
    VoteBalance DESC, TP.ViewCount DESC
LIMIT 10;
