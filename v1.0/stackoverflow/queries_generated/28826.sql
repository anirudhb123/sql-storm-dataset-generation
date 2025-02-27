WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC, p.Score DESC) AS Rank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        STRING_TO_ARRAY(substring(p.Tags, 2, LENGTH(p.Tags)-2), '><') AS tag_name 
        ON tag_name IS NOT NULL
    JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.PostTypeId = 1 -- Focus on questions only
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate
),
PopularPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CreationDate,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 -- Top 10 posts by view count in each type
),
PostStatistics AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.ViewCount,
        pp.Score,
        pp.CreationDate,
        pp.Tags,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pp.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pp.PostId AND v.VoteTypeId = 2) AS UpVoteCount, -- upvotes
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pp.PostId AND v.VoteTypeId = 3) AS DownVoteCount -- downvotes
    FROM 
        PopularPosts pp
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.Tags,
    CASE 
        WHEN ps.Score >= 0 THEN 'Positive'
        WHEN ps.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreCategory
FROM 
    PostStatistics ps
ORDER BY 
    ps.ViewCount DESC,
    ps.Score DESC;
