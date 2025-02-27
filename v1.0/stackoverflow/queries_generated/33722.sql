WITH RECURSIVE UserVoteDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        V.VoteTypeId,
        P.Title,
        V.CreationDate AS VoteDate,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY V.CreationDate DESC) AS VoteRank
    FROM 
        Users U
    JOIN 
        Votes V ON U.Id = V.UserId
    JOIN 
        Posts P ON V.PostId = P.Id
    WHERE 
        U.Reputation > 1000
        AND V.CreationDate BETWEEN CURRENT_DATE - INTERVAL '1 year' AND CURRENT_DATE
),
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount,
        STRING_AGG(C.Text, ', ') AS LatestComments
    FROM 
        Comments C
    GROUP BY 
        C.PostId
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(PH.Comment, '; ') AS EditComments
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 24) -- Edit Title, Edit Body, Suggested Edit Applied
    GROUP BY 
        PH.PostId, PH.UserId
)
SELECT 
    P.Id AS PostId,
    P.Title,
    P.ViewCount,
    COALESCE(PH.LastEditDate, 'No Edits') AS LastEditDate,
    COALESCE(PD.CommentCount, 0) AS TotalComments,
    COALESCE(PD.LatestComments, 'No Comments') AS LatestComments,
    U.DisplayName AS LastEditor,
    U.Reputation AS EditorReputation,
    U.VoteTypeId AS LastVoteType,
    U.VoteDate AS LastVoteDate
FROM 
    Posts P
LEFT JOIN 
    PostHistoryDetails PH ON P.Id = PH.PostId
LEFT JOIN 
    PostComments PD ON P.Id = PD.PostId
LEFT JOIN 
    UserVoteDetails U ON P.OwnerUserId = U.UserId AND U.VoteRank = 1
WHERE 
    P.CreationDate > CURRENT_DATE - INTERVAL '1 month'
    AND (P.Score > 10 OR P.ViewCount > 100)
ORDER BY 
    P.ViewCount DESC, 
    PH.LastEditDate DESC NULLS LAST
LIMIT 50;

