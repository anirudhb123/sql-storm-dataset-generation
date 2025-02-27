WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerName,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    AND 
        p.PostTypeId = 1  -- Only questions
),
FrequentTags AS (
    SELECT 
        UNNEST(string_to_array(Tags, '>')) AS TagName
    FROM 
        RankedPosts
),
TagOccurrence AS (
    SELECT 
        TagName,
        COUNT(*) AS OccurrenceCount
    FROM 
        FrequentTags
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 5  -- Tags that appear more than 5 times
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS NumberOfCloseActions
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Close and Reopen actions
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.ViewCount,
        COALESCE(CPH.NumberOfCloseActions, 0) AS CloseActions,
        STRING_AGG(DISTINCT TO_CHAR(T.TagName, 'FM9999999999')) AS RelatedTags
    FROM 
        RankedPosts RP
    LEFT JOIN 
        ClosedPostHistory CPH ON RP.PostId = CPH.PostId
    LEFT JOIN 
        FrequentTags T ON T.TagName = ANY(string_to_array(RP.Tags, '>'))
    WHERE 
        RP.TagRank <= 3  -- Top 3 posts per tag
    GROUP BY 
        RP.PostId
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.Score,
    TP.ViewCount,
    TP.CloseActions,
    TP.RelatedTags
FROM 
    TopPosts TP
ORDER BY 
    TP.Score DESC, 
    TP.ViewCount DESC
LIMIT 10;  -- Top 10 posts based on score and view count
