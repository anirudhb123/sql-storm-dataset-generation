WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        RP.* 
    FROM 
        RankedPosts RP
    WHERE 
        RP.TagRank <= 3
),
PostAnalysis AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.OwnerDisplayName,
        COUNT(DISTINCT bh.Id) AS EditCount,
        MAX(bh.CreationDate) AS LastEditDate
    FROM 
        TopPosts TP
    LEFT JOIN 
        PostHistory bh ON TP.PostId = bh.PostId 
        AND bh.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        TP.PostId, TP.Title, TP.OwnerDisplayName
)

SELECT 
    PA.*,
    TP.Tags,
    PA.EditCount,
    PA.LastEditDate
FROM 
    PostAnalysis PA
JOIN 
    TopPosts TP ON PA.PostId = TP.PostId
ORDER BY 
    PA.LastEditDate DESC, 
    PA.EditCount DESC;

-- This query aims to benchmark string processing by retrieving top questions over the last year based on tags and analyzing their editing history.
