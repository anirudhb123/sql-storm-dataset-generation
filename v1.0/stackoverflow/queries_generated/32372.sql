WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.ParentId,
        0 AS Level
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Questions only
    UNION ALL
    SELECT 
        P.Id,
        P.ParentId,
        R.Level + 1
    FROM 
        Posts P
    INNER JOIN 
        RecursivePostHierarchy R ON P.ParentId = R.PostId
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id
),
TopPosters AS (
    SELECT 
        U.Id,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(P.AnswerCount) AS TotalAnswers
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1 -- Questions only
    GROUP BY 
        U.Id
    HAVING 
        COUNT(P.Id) > 10
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        COUNT(*) AS EditCount,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.CreationDate END) AS ClosedDate
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.UpVotes,
    PS.DownVotes,
    PS.CommentCount,
    COALESCE(CPH.EditCount, 0) AS EditCount,
    CPH.ClosedDate,
    U.DisplayName AS TopPoster,
    TPT.PostCount,
    TPT.TotalAnswers,
    RPH.Level AS HierarchyLevel
FROM 
    PostSummary PS
LEFT JOIN 
    ClosedPostHistory CPH ON PS.PostId = CPH.PostId
LEFT JOIN 
    Users U ON PS.PostId = U.Id
LEFT JOIN 
    TopPosters TPT ON U.Id = TPT.Id
LEFT JOIN 
    RecursivePostHierarchy RPH ON PS.PostId = RPH.PostId
WHERE 
    PS.RN = 1
      AND (PS.Score > 0 OR PS.AnswerCount > 0)
      AND (PS.ViewCount > 100 OR U.Reputation > 1000)
ORDER BY 
    PS.Score DESC, 
    PS.CreationDate DESC;
