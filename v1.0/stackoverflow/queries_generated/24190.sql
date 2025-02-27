WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),

CTE_ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserDisplayName,
        CT.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CT ON PH.Comment::int = CT.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) AND 
        PH.CreationDate >= NOW() - INTERVAL '6 months'
),

UserVotes AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN VT.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VT.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Votes V
    JOIN 
        VoteTypes VT ON V.VoteTypeId = VT.Id
    GROUP BY 
        V.PostId
),

TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 10
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    COALESCE(UV.UpVotes, 0) AS UpVotes,
    COALESCE(UV.DownVotes, 0) AS DownVotes,
    CT.CloseReason,
    TS.TagName,
    TS.PostCount AS TagPostCount,
    TS.TotalScore
FROM 
    RankedPosts RP
LEFT JOIN 
    UserVotes UV ON RP.PostId = UV.PostId
LEFT JOIN 
    CTE_ClosedPosts CT ON RP.PostId = CT.PostId
LEFT JOIN 
    TagStatistics TS ON RP.Title ILIKE '%' || TS.TagName || '%'
WHERE 
    RP.PostRank = 1
AND 
    (RP.Score > 0 OR CT.CloseReason IS NOT NULL)
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC;

This SQL query performs an intricate performance benchmark on a Stack Overflow-like schema. It incorporates window functions to rank posts by score within their type, correlated subqueries to track votes, and CTEs for closed posts with specific reasons. It also utilizes string manipulation to associate tags effectively and includes conditions to filter out posts according to various semantic cases, such as ranking and view counts, while accounting for closed status and engagement metrics. The goal is to produce a comprehensive and actionable dataset for analysis within the parameters defined.
