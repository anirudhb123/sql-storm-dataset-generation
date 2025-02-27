WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(P.ViewCount) AS AvgViewCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
),
PostWithVotes AS (
    SELECT 
        P.Id AS PostId,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
FinalStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.PostCount,
        U.QuestionCount,
        U.AnswerCount,
        U.AvgViewCount,
        COALESCE(PWV.UpVotes, 0) AS UpVotes,
        COALESCE(PWV.DownVotes, 0) AS DownVotes,
        COALESCE(PHS.EditCount, 0) AS EditCount,
        COALESCE(PHS.LastEditDate, '1970-01-01') AS LastEditDate,
        COALESCE(PHS.HistoryTypes, 'No Edits') AS HistoryTypes
    FROM 
        UserStats U
    LEFT JOIN 
        PostWithVotes PWV ON U.UserId IN (SELECT OwnerUserId FROM Posts WHERE OwnerUserId IS NOT NULL)
    LEFT JOIN 
        PostHistorySummary PHS ON PHS.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = U.UserId)
)

SELECT 
    *
FROM 
    FinalStats
WHERE 
    Reputation > 1000 AND 
    (QuestionCount > 5 OR AnswerCount > 10)
ORDER BY 
    UpVotes DESC, 
    Reputation DESC;
