WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.ViewCount > 1000
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Title, Body, Tags edits
    GROUP BY 
        ph.PostId
),
PostsWithEdits AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        re.LastEditDate,
        COALESCE(re.EditCount, 0) AS EditCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentEdits re ON rp.Id = re.PostId
)
SELECT 
    pwe.Title,
    pwe.CreationDate,
    pwe.ViewCount,
    pwe.Score,
    pwe.AnswerCount,
    COALESCE(pwe.LastEditDate, 'No edits made') AS LastEditDetails,
    CASE 
        WHEN pwe.EditCount > 5 THEN 'Highly Edited'
        WHEN pwe.EditCount BETWEEN 1 AND 5 THEN 'Moderately Edited'
        ELSE 'Not Edited'
    END AS EditCategory
FROM 
    PostsWithEdits pwe
WHERE 
    pwe.Rank <= 3 -- Top 3 posts per user
ORDER BY 
    pwe.Score DESC, pwe.ViewCount DESC;
