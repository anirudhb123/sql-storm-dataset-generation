WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(*) OVER (PARTITION BY p.PostTypeId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= current_date - INTERVAL '1 year'
),
PostWithTags AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.Rank,
        ARRAY_LENGTH(string_to_array(rp.Title, ' '), 1) AS TitleWordCount,
        CASE 
            WHEN rp.OwnerUserId IS NOT NULL THEN 'User Existence Verified'
            ELSE 'Missing User'
        END AS UserStatus
    FROM 
        RankedPosts rp
),
PostHistoryAnalysis AS (
    SELECT 
        p.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        SUM(CASE WHEN pht.Name = 'Edit Body' THEN 1 ELSE 0 END) AS BodyEdits,
        SUM(CASE WHEN pht.Name = 'Edit Title' THEN 1 ELSE 0 END) AS TitleEdits
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    INNER JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        p.PostId
),
FinalPostMetrics AS (
    SELECT 
        pt.PostId,
        pt.Title,
        pt.ViewCount,
        pt.Score,
        pha.EditCount,
        pha.LastEditDate,
        pha.BodyEdits,
        pt.TitleWordCount,
        pt.UserStatus
    FROM 
        PostWithTags pt
    LEFT JOIN 
        PostHistoryAnalysis pha ON pt.PostId = pha.PostId
    WHERE 
        pt.Rank <= 5
)
SELECT 
    DISTINCT 
    COALESCE(fpm.Title, 'Unknown Title') AS Post_Title,
    fpm.ViewCount,
    fpm.Score,
    fpm.EditCount,
    CASE 
        WHEN fpm.BodyEdits > 0 THEN 'Edited Body'
        ELSE 'No Body Edits'
    END AS Body_Edited_Status,
    CASE 
        WHEN fpm.LastEditDate IS NOT NULL THEN fpm.LastEditDate
        ELSE NULL
    END AS Last_Edited_On,
    CASE 
        WHEN fpm.TitleWordCount > 10 THEN 'Long Title'
        ELSE 'Short Title'
    END AS Title_Length,
    COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS Total_Upvotes
FROM 
    FinalPostMetrics fpm
LEFT JOIN 
    Votes v ON fpm.PostId = v.PostId
GROUP BY 
    fpm.PostId, fpm.Title, fpm.ViewCount, fpm.Score, fpm.EditCount, fpm.BodyEdits, fpm.LastEditDate, fpm.TitleWordCount
ORDER BY 
    fpm.Score DESC, fpm.ViewCount DESC, fpm.EditCount DESC
LIMIT 50;
