
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        @row_number := IF(@prev_post_type = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_type := p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId,
        (SELECT @row_number := 0, @prev_post_type := 0) AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
TopComments AS (
    SELECT 
        pc.PostId,
        GROUP_CONCAT(pc.Text SEPARATOR ' | ') AS TopCommentTexts
    FROM 
        (SELECT 
             c.PostId,
             c.Text,
             @comment_row_number := IF(@prev_comment_post = c.PostId, @comment_row_number + 1, 1) AS CommentRank,
             @prev_comment_post := c.PostId
         FROM 
            Comments c,
            (SELECT @comment_row_number := 0, @prev_comment_post := 0) AS vars
         WHERE 
            c.CreationDate >= NOW() - INTERVAL 6 MONTH
        ) pc
    WHERE 
        pc.CommentRank <= 3  
    GROUP BY 
        pc.PostId
),
PostHistoryChanges AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL 3 MONTH
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        COALESCE(tc.TopCommentTexts, 'No comments') AS TopComments,
        COALESCE(SUM(phc.HistoryCount), 0) AS HistoryChanges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopComments tc ON rp.PostId = tc.PostId
    LEFT JOIN 
        PostHistoryChanges phc ON rp.PostId = phc.PostId
    WHERE 
        rp.Rank <= 10  
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.ViewCount, rp.CommentCount, rp.UpVotes, rp.DownVotes, tc.TopCommentTexts
    ORDER BY 
        rp.Score DESC
)

SELECT 
    f.PostId,
    f.Title,
    f.CreationDate,
    f.Score,
    f.ViewCount,
    f.CommentCount,
    f.UpVotes,
    f.DownVotes,
    f.TopComments,
    f.HistoryChanges
FROM 
    FinalResults f
WHERE 
    f.Score IS NOT NULL 
    AND f.ViewCount > 100 
ORDER BY 
    f.ViewCount DESC, f.Score DESC;
