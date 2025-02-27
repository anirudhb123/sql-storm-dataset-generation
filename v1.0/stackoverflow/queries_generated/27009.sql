WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2  -- Answers
    LEFT JOIN 
        LATERAL STRING_TO_ARRAY(p.Tags, ', ') AS split_tags ON TRUE
    LEFT JOIN 
        Tags t ON trim(split_tags) = t.TagName
    WHERE 
        p.PostTypeId = 1  -- Questions only
    GROUP BY 
        p.Id, U.DisplayName
),

RecentPosts AS (
    SELECT 
        p.*,
        PH.Comment AS LastEditComment,
        PH.CreationDate AS LastEditDate,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    JOIN 
        PostHistory PH ON p.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5)  -- Edit Title or Edit Body
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
)

SELECT 
    R.PostId,
    R.Title,
    R.Body,
    R.OwnerDisplayName,
    R.ViewCount,
    R.AnswerCount,
    R.Tags,
    COALESCE(RP.LastEditComment, 'No Edits Yet') AS LastEditComment,
    RP.LastEditDate AS LastEditDate,
    RP.RecentRank
FROM 
    RankedPosts R
LEFT JOIN 
    RecentPosts RP ON R.PostId = RP.Id
WHERE 
    R.PostRank = 1
ORDER BY 
    R.ViewCount DESC, R.CreationDate DESC
LIMIT 50;
