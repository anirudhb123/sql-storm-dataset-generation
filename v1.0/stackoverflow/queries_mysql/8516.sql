
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        P.Score,
        U.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RP.CreationDate,
        RP.Score,
        RP.Author
    FROM 
        RankedPosts RP
    WHERE 
        RP.Rank <= 5
),
PostVoteDetails AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.ViewCount,
    TP.CreationDate,
    TP.Score,
    TP.Author,
    COALESCE(PVD.UpVotes, 0) AS UpVotes,
    COALESCE(PVD.DownVotes, 0) AS DownVotes
FROM 
    TopPosts TP
LEFT JOIN 
    PostVoteDetails PVD ON TP.PostId = PVD.PostId
ORDER BY 
    TP.ViewCount DESC;
