
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
        AND p.Score IS NOT NULL
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 10
        AND rp.UpVoteCount - rp.DownVoteCount > 0 
),
PostComments AS (
    SELECT 
        fp.PostId,
        GROUP_CONCAT(c.Text ORDER BY c.CreationDate SEPARATOR ' | ') AS AllComments
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Comments c ON fp.PostId = c.PostId
    GROUP BY 
        fp.PostId
)
SELECT 
    fp.Title,
    fp.CreationDate,
    LEAST(fp.ViewCount, 100) AS LimitedViewCount, 
    COALESCE(pc.AllComments, 'No comments available') AS Comments,
    CASE 
        WHEN fp.Score IS NULL THEN 'Unscored'
        WHEN fp.Score > 50 THEN 'High Score'
        ELSE 'Low Score' 
    END AS ScoreCategory,
    CASE 
        WHEN fp.CommentCount = 0 THEN 'No Comments'
        WHEN fp.CommentCount >= 5 THEN 'Many Comments'
        ELSE 'Few Comments'
    END AS CommentCategory,
    (SELECT COUNT(*) FROM Posts ph WHERE ph.ParentId = fp.PostId) AS AnswerCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostComments pc ON fp.PostId = pc.PostId
ORDER BY 
    fp.CreationDate DESC
LIMIT 25 OFFSET 0;
