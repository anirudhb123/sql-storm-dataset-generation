WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COALESCE((
            SELECT COUNT(*) 
            FROM Comments c 
            WHERE c.PostId = p.Id
        ), 0) AS CommentCount,
        COALESCE((
            SELECT COUNT(*) 
            FROM Votes v 
            WHERE v.PostId = p.Id AND v.VoteTypeId = 2
        ), 0) AS UpVoteCount,
        COALESCE((
            SELECT COUNT(*) 
            FROM Votes v 
            WHERE v.PostId = p.Id AND v.VoteTypeId = 3
        ), 0) AS DownVoteCount,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days' 
        AND p.PostTypeId = 1  -- Questions only
),
FilteredPosts AS (
    SELECT 
        rp.*,
        STRING_AGG(DISTINCT t.TagName, ', ') AS AllTags
    FROM 
        RecentPosts rp
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(rp.Tags, '<>')) AS tag ON 
        tag IS NOT NULL
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        rp.PostId
),
RankedPosts AS (
    SELECT 
        fp.*,
        RANK() OVER (ORDER BY fp.Score DESC, fp.ViewCount DESC) AS ScoreRank
    FROM 
        FilteredPosts fp
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.AllTags,
    rp.ScoreRank
FROM 
    RankedPosts rp
WHERE 
    rp.ScoreRank <= 10  -- Top 10 questions based on score and view count
ORDER BY 
    rp.ScoreRank;
