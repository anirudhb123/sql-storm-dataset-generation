WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= DATEADD(MONTH, -6, GETDATE())
      AND 
        P.Score > 0
),
RecentComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount,
        MAX(C.CreationDate) AS LastCommentDate
    FROM 
        Comments C
    WHERE 
        C.CreationDate >= DATEADD(DAY, -30, GETDATE())
    GROUP BY 
        C.PostId
),
PostVoteSummary AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.OwnerDisplayName,
    ISNULL(RC.CommentCount, 0) AS CommentCount,
    ISNULL(RC.LastCommentDate, 'No Comments') AS LastCommentDate,
    ISNULL(PVS.UpVotes, 0) AS UpVotes,
    ISNULL(PVS.DownVotes, 0) AS DownVotes,
    RP.CreationDate,
    CASE 
        WHEN RP.CreationDate > DATEADD(DAY, -7, GETDATE()) THEN 'New'
        WHEN RP.Rank <= 3 THEN 'Top'
        ELSE 'Regular'
    END AS PostCategory
FROM 
    RankedPosts RP
LEFT JOIN 
    RecentComments RC ON RP.PostId = RC.PostId
LEFT JOIN 
    PostVoteSummary PVS ON RP.PostId = PVS.PostId
ORDER BY 
    RP.Score DESC, RP.CreationDate DESC
