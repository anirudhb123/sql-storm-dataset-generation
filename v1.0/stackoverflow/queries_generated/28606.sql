WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only include questions
        AND p.AnswerCount > 0 -- Only questions with answers
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- Get top 5 ranked posts for each tag
),
PostStats AS (
    SELECT 
        fp.PostId,
        fp.OwnerDisplayName,
        fp.Title,
        fp.CreationDate,
        fp.Score,
        fp.ViewCount,
        CONCAT_WS(', ', SPLIT_PARTS(fp.Tags)) AS FormattedTags,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = fp.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = fp.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = fp.PostId AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        FilteredPosts fp
)
SELECT 
    ps.*,
    ARRAY_AGG(DISTINCT b.Name) AS BadgeNames
FROM 
    PostStats ps
LEFT JOIN 
    Badges b ON ps.OwnerDisplayName = b.UserId
GROUP BY 
    ps.PostId, ps.OwnerDisplayName, ps.Title, ps.CreationDate, ps.Score, ps.ViewCount, ps.FormattedTags
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
