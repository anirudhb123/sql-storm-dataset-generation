WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerName,
        P.Score,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.ViewCount, 0) AS ViewCount,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.OwnerName,
        RP.Score,
        RP.AnswerCount,
        RP.ViewCount,
        PH.UserId AS LastEditorId,
        PH.UserDisplayName AS LastEditorName,
        PH.LastEditDate
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostHistory PH ON RP.PostId = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 6) 
    WHERE 
        RP.Rank <= 10
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.OwnerName,
    PD.Score,
    PD.AnswerCount,
    PD.ViewCount,
    PD.LastEditorName,
    PD.LastEditDate,
    CASE 
        WHEN PD.LastEditDate IS NOT NULL THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus
FROM 
    PostDetails PD
ORDER BY 
    PD.Score DESC, 
    PD.CreationDate DESC;
