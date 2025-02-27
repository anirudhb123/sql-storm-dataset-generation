WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        u.DisplayName AS AuthorDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.ViewCount > 1000 -- Consider only popular posts
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName AS EditorDisplayName,
        ph.CreationDate AS EditDate,
        ph.Comment AS EditReason,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, Tags
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.ViewCount,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.Score,
    rp.AuthorDisplayName,
    re.EditorDisplayName,
    re.EditDate,
    re.EditReason,
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.TotalScore
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentEdits re ON rp.PostId = re.PostId AND re.EditRank = 1 -- Get the most recent edit only
LEFT JOIN 
    TagStatistics ts ON rp.Tags LIKE '%' || ts.TagName || '%' -- Match tags
WHERE 
    rp.Rank = 1 -- Get the latest post by each user
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC; -- Order by score and view count for relevance
