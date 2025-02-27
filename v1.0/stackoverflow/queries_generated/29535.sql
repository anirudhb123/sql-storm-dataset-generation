WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByTag
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
TagSummary AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS UpvotedCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    GROUP BY 
        Tag
),
TopOwner AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only questions
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 10 -- More than 10 questions
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
)
SELECT 
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.OwnerDisplayName,
    ts.Tag,
    ts.PostCount AS TotalPostsByTag,
    ts.UpvotedCount AS TotalUpvotedByTag,
    op.TotalPosts AS OwnerTotalPosts,
    cpd.ClosedDate,
    cpd.CloseReason
FROM 
    RankedPosts rp
LEFT JOIN 
    TagSummary ts ON rp.Tags LIKE '%' || ts.Tag || '%'
LEFT JOIN 
    TopOwner op ON rp.OwnerUserId = op.OwnerUserId
LEFT JOIN 
    ClosedPostDetails cpd ON rp.PostId = cpd.PostId
WHERE 
    rp.RankByTag = 1 -- Get only the top-ranked post per tag
ORDER BY 
    ts.PostCount DESC, rp.Score DESC;
