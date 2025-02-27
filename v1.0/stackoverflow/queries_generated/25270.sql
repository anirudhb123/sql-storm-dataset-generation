WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY t.Id ORDER BY p.CreationDate DESC) AS PostRank,
        t.TagName
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- only Questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.TagName,
        COALESCE(PH.RevisionsCount, 0) AS RevisionsCount
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS RevisionsCount
        FROM 
            PostHistory
        WHERE 
            PostHistoryTypeId NOT IN (10, 12)  -- Exclude closed/deleted posts
        GROUP BY 
            PostId
    ) PH ON rp.PostId = PH.PostId
    WHERE 
        rp.PostRank <= 5  -- Retrieve top 5 posts per tag
)
SELECT 
    fp.*,
    PH.Comment AS PostEditComment
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistory PH ON fp.PostId = PH.PostId
WHERE 
    PH.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
ORDER BY 
    fp.TagName, fp.Score DESC, fp.RevisionsCount DESC;
