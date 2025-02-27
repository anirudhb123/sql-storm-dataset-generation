WITH RecursivePostStats AS (
    SELECT 
        P.Id AS PostId,
        P.CreationDate,
        P.OwnerUserId,
        P.Title,
        P.Body,
        0 AS Level,
        P.AcceptedAnswerId
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Questions only
    UNION ALL
    SELECT 
        A.Id,
        A.CreationDate,
        A.OwnerUserId,
        A.Title,
        A.Body,
        Level + 1,
        A.AcceptedAnswerId
    FROM 
        Posts A
    INNER JOIN 
        RecursivePostStats R ON R.PostId = A.ParentId
    WHERE 
        A.PostTypeId = 2  -- Answers only
),
PostVoteStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        MAX(PH.CreationDate) OVER (PARTITION BY PH.PostId) AS LatestEditDate,
        PH.UserDisplayName
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
),
CombinedCounts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate AS QuestionDate,
        PVS.VoteCount,
        PVS.UpVotes,
        PVS.DownVotes,
        COALESCE(PHD.LatestEditDate, PS.CreationDate) AS LatestEditDate,
        PHD.UserDisplayName AS LastEditedBy,
        PS.AcceptedAnswerId
    FROM 
        RecursivePostStats PS
    LEFT JOIN 
        PostVoteStats PVS ON PS.PostId = PVS.PostId
    LEFT JOIN 
        PostHistoryDetails PHD ON PS.PostId = PHD.PostId
)
SELECT 
    C.PostId,
    C.Title,
    C.QuestionDate,
    C.VoteCount,
    C.UpVotes,
    C.DownVotes,
    C.LatestEditDate,
    C.LastEditedBy,
    COALESCE(RP.Title, 'No Accepted Answer') AS AcceptedAnswerTitle
FROM 
    CombinedCounts C
LEFT JOIN 
    Posts RP ON C.AcceptedAnswerId = RP.Id
WHERE 
    C.LatestEditDate < CURRENT_TIMESTAMP - INTERVAL '30 days'  -- Filter for outdated questions
ORDER BY 
    C.QuestionDate DESC, C.VoteCount DESC
LIMIT 50;
