WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswer,
        U.DisplayName AS OwnerDisplayName,
        PT.Name AS PostType
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
RankedPosts AS (
    SELECT 
        PD.*,
        ROW_NUMBER() OVER (PARTITION BY PD.PostType ORDER BY PD.ViewCount DESC) AS Rank
    FROM 
        PostDetails PD
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.ViewCount,
    RP.CreationDate,
    RP.OwnerDisplayName,
    RP.PostType,
    UV.TotalVotes,
    UV.UpVotes,
    UV.DownVotes
FROM 
    RankedPosts RP
LEFT JOIN 
    UserVotes UV ON UV.UserId = RP.OwnerDisplayName
WHERE 
    RP.Rank <= 10
ORDER BY 
    RP.ViewCount DESC, RP.CreationDate DESC
UNION ALL
SELECT 
    NULL AS PostId,
    'Summary' AS Title,
    SUM(RP.ViewCount) AS TotalViewCount,
    NULL AS CreationDate,
    NULL AS OwnerDisplayName,
    NULL AS PostType,
    SUM(UV.TotalVotes) AS TotalVotes,
    SUM(UV.UpVotes) AS TotalUpVotes,
    SUM(UV.DownVotes) AS TotalDownVotes
FROM 
    RankedPosts RP
LEFT JOIN 
    UserVotes UV ON UV.UserId = RP.OwnerDisplayName
HAVING 
    COUNT(RP.PostId) > 0;
