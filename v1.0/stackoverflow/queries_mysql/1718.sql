
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        @row_number := IF(@prev_post_type = p.PostTypeId, @row_number + 1, 1) AS PostRank,
        @prev_post_type := p.PostTypeId
    FROM 
        Posts p, (SELECT @row_number := 0, @prev_post_type := NULL) AS init
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY 
        p.PostTypeId, p.Score DESC
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotesCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotesCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
FilteredPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        COALESCE(pv.UpVotesCount, 0) AS UpVotes,
        COALESCE(pv.DownVotesCount, 0) AS DownVotes
    FROM 
        RankedPosts r
    LEFT JOIN 
        PostVotes pv ON r.PostId = pv.PostId
    WHERE 
        r.PostRank <= 10
),
CommentsInfo AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(c.Text SEPARATOR '; ') AS CommentTexts
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.UpVotes,
    fp.DownVotes,
    COALESCE(ci.CommentCount, 0) AS TotalComments,
    COALESCE(ci.CommentTexts, '') AS LastCommentsSnippet
FROM 
    FilteredPosts fp
LEFT JOIN 
    CommentsInfo ci ON fp.PostId = ci.PostId
ORDER BY 
    fp.Score DESC, fp.ViewCount ASC;
