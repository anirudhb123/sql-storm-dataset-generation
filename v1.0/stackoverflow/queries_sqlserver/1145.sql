
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankScore
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
),
FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RP.OwnerDisplayName
    FROM 
        RankedPosts RP
    WHERE 
        RP.RankScore <= 5
),
PostVoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        FP.PostId,
        FP.Title,
        FP.ViewCount,
        FP.OwnerDisplayName,
        ISNULL(PVS.UpVotes, 0) AS UpVotes,
        ISNULL(PVS.DownVotes, 0) AS DownVotes,
        (FP.ViewCount + ISNULL(PVS.UpVotes, 0) - ISNULL(PVS.DownVotes, 0)) AS AdjustedScore
    FROM 
        FilteredPosts FP
    LEFT JOIN 
        PostVoteStats PVS ON FP.PostId = PVS.PostId
)
SELECT 
    PD.Title,
    PD.ViewCount,
    PD.OwnerDisplayName,
    PD.AdjustedScore,
    'This post has ' + CAST(PD.UpVotes AS VARCHAR(10)) + ' upvotes and ' + CAST(PD.DownVotes AS VARCHAR(10)) + ' downvotes.' AS VoteSummary
FROM 
    PostDetails PD
ORDER BY 
    PD.AdjustedScore DESC, 
    PD.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
