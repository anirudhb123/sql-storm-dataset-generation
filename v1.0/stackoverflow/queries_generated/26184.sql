WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.Id = ANY(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><'))::int[])
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName
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
        rp.CommentCount,
        rp.Tags,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5  -- Top 5 questions per user
    ORDER BY 
        rp.Score DESC
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        p.Title AS PostTitle,
        p.Body AS PostBody,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName AS Editor,
        ph.Comment,
        ph.Text AS NewValue
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'  -- Recent history
)
SELECT 
    fp.Title,
    fp.OwnerDisplayName,
    fp.Score,
    fp.Tags,
    COUNT(DISTINCT pvd.Id) AS VoteCount,
    ARRAY_AGG(DISTINCT COALESCE(phd.Editor, 'N/A')) AS Editors,
    ARRAY_AGG(DISTINCT phd.Comment) AS EditComments,
    STRING_AGG(DISTINCT phd.NewValue, '| ') AS RecentChanges
FROM 
    FilteredPosts fp
LEFT JOIN 
    Votes v ON fp.PostId = v.PostId
LEFT JOIN 
    PostHistoryDetails phd ON fp.PostId = phd.PostId
WHERE 
    fp.ViewCount > 100  -- Only questions with more than 100 views
GROUP BY 
    fp.Title, fp.OwnerDisplayName, fp.Score, fp.Tags
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;
