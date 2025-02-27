WITH RecursivePostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.CreationDate,
        1 as Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1  -- Selecting only questions

    UNION ALL

    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.CreationDate,
        R.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        Posts AP ON P.Id = AP.ParentId  -- Joining with answers
    INNER JOIN 
        RecursivePostStats R ON R.PostId = AP.ParentId -- Recursive join
),
VoteStatistics AS (
    SELECT 
        V.PostId,
        V.VoteTypeId,
        COUNT(V.Id) AS VoteCount
    FROM 
        Votes V
    GROUP BY 
        V.PostId, V.VoteTypeId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(U.Reputation) AS TotalReputation
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
    ORDER BY 
        TotalReputation DESC
    LIMIT 10
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        COUNT(PH.Id) AS HistoryCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.CreationDate,
    COALESCE(VS.VoteCount, 0) AS TotalVotes,
    TH.HistoryCount,
    TU.DisplayName,
    TU.TotalReputation
FROM 
    RecursivePostStats PS
LEFT JOIN 
    VoteStatistics VS ON PS.PostId = VS.PostId AND VS.VoteTypeId = 2 -- Upvotes
LEFT JOIN 
    PostHistorySummary TH ON PS.PostId = TH.PostId
LEFT JOIN 
    TopUsers TU ON PS.CreationDate >= NOW() - INTERVAL '1 year' -- Users active in the last year
WHERE 
    PS.Score > 10   -- Filtering posts with higher scores
ORDER BY 
    PS.CreationDate DESC, TotalVotes DESC
LIMIT 50;  -- Limiting the result to top 50 entries
