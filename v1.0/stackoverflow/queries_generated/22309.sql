WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title, 
        PT.Name AS PostType,
        U.DisplayName AS OwnerDisplayName, 
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY PT.Name ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AvgScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    WHERE 
        T.IsRequired = 1
    GROUP BY 
        T.TagName
),
PostVoteSummary AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN VT.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VT.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    JOIN 
        VoteTypes VT ON V.VoteTypeId = VT.Id
    GROUP BY 
        V.PostId
),
TopClosedPosts AS (
    SELECT 
        PH.PostId, 
        COUNT(*) AS CloseCount
    FROM 
        PostHistory PH 
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        PH.PostId
    HAVING 
        COUNT(*) > 2
),
FinalResults AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.PostType,
        RP.OwnerDisplayName,
        RP.CreationDate,
        PS.PostCount,
        PS.AvgScore,
        COALESCE(PVS.UpVotes, 0) AS UpVotes,
        COALESCE(PVS.DownVotes, 0) AS DownVotes,
        TCP.CloseCount
    FROM 
        RankedPosts RP
    LEFT JOIN 
        TagStatistics PS ON PS.PostCount > 0 AND RP.Title LIKE CONCAT('%', PS.TagName, '%')
    LEFT JOIN 
        PostVoteSummary PVS ON PVS.PostId = RP.PostId
    LEFT JOIN 
        TopClosedPosts TCP ON TCP.PostId = RP.PostId
    WHERE 
        RP.PostRank <= 10
)

SELECT 
    *,
    CASE 
        WHEN CloseCount IS NOT NULL THEN 'Closed More Than Twice'
        ELSE 'Active Post'
    END AS PostStatus
FROM 
    FinalResults
WHERE 
    (UpVotes - DownVotes) > 5 
    OR PostType = 'Answer'
ORDER BY 
    CreationDate DESC, AvgScore DESC;

