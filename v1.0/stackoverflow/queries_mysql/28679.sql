
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        u.DisplayName AS AuthorDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName AS EditorDisplayName,
        ph.CreationDate AS EditDate,
        ph.Comment,
        ph.Text AS NewValue,
        p.Title AS PostTitle,
        r.TagRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        RankedPosts r ON p.Id = r.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
        AND ph.CreationDate >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
)
SELECT 
    rp.PostId,
    rp.Title AS QuestionTitle,
    rp.AuthorDisplayName,
    rp.ViewCount,
    rp.Score,
    re.EditorDisplayName,
    re.EditDate,
    re.Comment,
    re.NewValue,
    re.TagRank
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentEdits re ON rp.PostId = re.PostId
WHERE 
    rp.TagRank <= 5 
ORDER BY 
    rp.Title, rp.ViewCount DESC, rp.CreationDate DESC;
