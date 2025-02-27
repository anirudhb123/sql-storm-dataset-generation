WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        T.TagsArray,
        COUNT(C.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        LATERAL (
            SELECT 
                string_agg(T.TagName, ', ') AS TagsArray
            FROM 
                Tags T
            WHERE 
                T.Id = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><')::int[])
        ) AS T ON true
    WHERE 
        P.PostTypeId = 1 -- Considering only questions
    GROUP BY 
        P.Id, U.DisplayName, P.Title, P.Body, P.CreationDate, P.ViewCount, P.Score
), 
PopularityRank AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        Score + COALESCE(CommentCount, 0) AS PopularityScore
    FROM 
        RankedPosts
), 
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PHT.Name AS PostHistoryTypeName,
        COUNT(PH.Id) AS HistoryCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId, PHT.Name, PH.PostHistoryTypeId
)

SELECT 
    PR.PostId,
    PR.Title,
    PR.OwnerDisplayName,
    PR.PopularityScore,
    array_agg(PHD.PostHistoryTypeName || ': ' || PHD.HistoryCount) AS HistorySummary,
    PR.Score,
    PR.ViewCount,
    PR.CreationDate,
    PHD.PostId AS HistoryPostId
FROM 
    PopularityRank PR
LEFT JOIN 
    PostHistoryDetails PHD ON PR.PostId = PHD.PostId
GROUP BY 
    PR.PostId, PR.Title, PR.OwnerDisplayName, PR.PopularityScore, PR.Score, PR.ViewCount, PR.CreationDate
ORDER BY 
    PR.PopularityScore DESC, PR.CreationDate DESC
LIMIT 10;
