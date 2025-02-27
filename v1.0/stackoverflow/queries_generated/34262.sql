WITH RecursivePostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(AC.AcceptedAnswerCount, 0) AS AcceptedAnswerCount,
        COALESCE(AC.ViewCountTotal, 0) AS ViewCountTotal
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS AcceptedAnswerCount,
            SUM(ViewCount) AS ViewCountTotal
        FROM 
            Posts
        WHERE PostTypeId = 2 AND AcceptedAnswerId IS NOT NULL
        GROUP BY PostId
    ) AC ON P.Id = AC.PostId
    WHERE 
        P.PostTypeId = 1 -- Questions only
),
UserRankings AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 0
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        H.Name AS HistoryType,
        COUNT(*) AS ChangeCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes H ON PH.PostHistoryTypeId = H.Id
    WHERE 
        H.Name IN ('Edit Title', 'Edit Body', 'Close')
    GROUP BY 
        PH.PostId, H.Name
),
FinalResults AS (
    SELECT 
        RPS.PostId,
        RPS.Title,
        RPS.CreationDate,
        RPS.AcceptedAnswerCount,
        RPS.ViewCountTotal,
        COALESCE(PHS.ChangeCount, 0) AS TotalChanges,
        UR.DisplayName,
        UR.ReputationRank
    FROM 
        RecursivePostStats RPS
    LEFT JOIN 
        PostHistorySummary PHS ON RPS.PostId = PHS.PostId
    JOIN 
        Posts P ON RPS.PostId = P.Id
    JOIN 
        Users UR ON P.OwnerUserId = UR.Id
    WHERE 
        RPS.ViewCountTotal > 10 -- Filter for highly viewed questions
)

SELECT 
    FR.PostId,
    FR.Title,
    FR.CreationDate,
    FR.AcceptedAnswerCount,
    FR.ViewCountTotal,
    FR.TotalChanges,
    FR.DisplayName,
    FR.ReputationRank
FROM 
    FinalResults FR
ORDER BY 
    FR.ViewCountTotal DESC, 
    FR.TotalChanges DESC
FETCH FIRST 10 ROWS ONLY;

-- This query provides insights on the top questions along with their author information, view counts, 
-- acceptance of answers, and the history of changes made to the posts.
