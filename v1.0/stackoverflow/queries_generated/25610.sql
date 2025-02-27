WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2 
    LEFT JOIN 
        STRING_TO_ARRAY(p.Tags, ',') AS tag_array ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_array
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),

PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.Tags,
        rp.AnswerCount,
        hp.UserDisplayName AS LastEditor,
        hp.CreationDate AS LastEditDate,
        hp.Comment,
        hp.Text
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory hp ON rp.PostId = hp.PostId
    WHERE 
        hp.PostHistoryTypeId IN (4, 5, 6) -- Grab revisions related to Title, Body, and Tags
),

DetailedStatistics AS (
    SELECT 
        ps.*,
        COUNT(v.Id) AS VoteCount,
        MAX(b.Date) AS FirstBadgeDate,
        MIN(b.Class) AS HighestBadgeClass
    FROM 
        PostStatistics ps
    LEFT JOIN 
        Votes v ON ps.PostId = v.PostId
    LEFT JOIN 
        Badges b ON ps.OwnerDisplayName = b.UserId
    GROUP BY 
        ps.PostId, ps.Title, ps.ViewCount, ps.OwnerDisplayName, 
        ps.Tags, ps.AnswerCount, ps.LastEditor, ps.LastEditDate, ps.Comment, ps.Text
)

SELECT 
    * 
FROM 
    DetailedStatistics
WHERE 
    FirstBadgeDate IS NOT NULL 
ORDER BY 
    ViewCount DESC, AnswerCount DESC, PostId;
