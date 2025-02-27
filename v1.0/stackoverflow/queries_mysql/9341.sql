
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        @row_number := IF(@current_post_type = pt.Name, @row_number + 1, 1) AS ScoreRank,
        @current_post_type := pt.Name,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @row_number := 0, @current_post_type := '') AS vars
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, pt.Name
),
FilteredPosts AS (
    SELECT 
        rp.*,
        (UNIX_TIMESTAMP() - UNIX_TIMESTAMP(rp.CreationDate)) / 3600 AS AgeInHours
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 5
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.AgeInHours
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, fp.AgeInHours ASC;
