WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    INNER JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND P.Score IS NOT NULL
),
TopPosts AS (
    SELECT 
        RP.* 
    FROM 
        RankedPosts RP
    WHERE 
        RP.Rank <= 5
),
PostVoteInfo AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes 
    GROUP BY 
        PostId
),
ClosedPosts AS (
    SELECT 
        HP.PostId,
        HP.CreationDate,
        H.Comment,
        H.UserDisplayName
    FROM 
        PostHistory HP
    INNER JOIN 
        PostHistoryTypes HT ON HP.PostHistoryTypeId = HT.Id
    LEFT JOIN 
        Users H ON HP.UserId = H.Id
    WHERE 
        HT.Name = 'Post Closed'
        AND HP.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
FinalPostReport AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.CreationDate,
        TP.OwnerDisplayName,
        COALESCE(PVI.UpVotes, 0) AS UpVotes,
        COALESCE(PVI.DownVotes, 0) AS DownVotes,
        COALESCE(CP.Comment, 'N/A') AS CloseComment,
        COALESCE(CP.UserDisplayName, 'N/A') AS ClosedBy,
        TP.Score,
        TP.ViewCount
    FROM 
        TopPosts TP
    LEFT JOIN 
        PostVoteInfo PVI ON TP.PostId = PVI.PostId
    LEFT JOIN 
        ClosedPosts CP ON TP.PostId = CP.PostId
)
SELECT 
    FPR.*,
    (FPR.UpVotes - FPR.DownVotes) AS NetScore,
    CASE 
        WHEN FPR.ClosedBy <> 'N/A' THEN 'Closed'
        ELSE 'Active'
    END AS Status
FROM 
    FinalPostReport FPR
ORDER BY 
    FPR.Score DESC, FPR.ViewCount DESC;
