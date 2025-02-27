WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        U.DisplayName AS OwnerName,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY U.Location ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  -- Only questions
        AND P.CreationDate >= NOW() - INTERVAL '1 year'  -- Last year
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.Tags,
        RP.OwnerName,
        RP.CreationDate,
        RP.Score
    FROM 
        RankedPosts RP
    WHERE 
        RP.Rank <= 5  -- Top 5 posts per location
),
PostDetails AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.Body,
        TP.Tags,
        TP.OwnerName,
        COUNT(C.CommentId) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM 
        TopPosts TP
    LEFT JOIN 
        Comments C ON C.PostId = TP.PostId
    LEFT JOIN 
        Votes V ON V.PostId = TP.PostId
    GROUP BY 
        TP.PostId, TP.Title, TP.Body, TP.Tags, TP.OwnerName
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.Body,
    PD.Tags,
    PD.OwnerName,
    PD.CommentCount,
    PD.VoteCount,
    CASE 
        WHEN PD.VoteCount > 10 THEN 'High Engagement'
        WHEN PD.VoteCount BETWEEN 5 AND 10 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    PostDetails PD
ORDER BY 
    PD.VoteCount DESC, PD.CommentCount DESC;
