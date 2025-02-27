WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.AnswerCount,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank,
        COALESCE(AVG(CASE WHEN V.VoteTypeId = 2 THEN 1 END), 0) AS AverageUpVotes,
        COALESCE(AVG(CASE WHEN V.VoteTypeId = 3 THEN 1 END), 0) AS AverageDownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate > (SELECT MAX(CreationDate) - INTERVAL '30 days' FROM Posts) 
        AND P.Score >= 10
    GROUP BY 
        P.Id, U.DisplayName
),
ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        PH.UserDisplayName,
        RANK() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
),
TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.OwnerDisplayName,
    RP.Rank,
    CP.CreationDate AS CloseDate,
    CP.Comment AS CloseComment,
    CP.UserDisplayName AS CloseBy,
    TS.TagName,
    TS.PostCount,
    TS.TotalViews,
    CASE 
        WHEN CP.CloseRank IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END AS PostStatus
FROM 
    RankedPosts RP
LEFT JOIN 
    ClosedPostHistory CP ON RP.PostId = CP.PostId AND CP.CloseRank = 1
LEFT JOIN 
    TagStats TS ON RP.Tags LIKE '%' || TS.TagName || '%'
ORDER BY 
    RP.Rank,
    RP.PostId DESC
LIMIT 100;
