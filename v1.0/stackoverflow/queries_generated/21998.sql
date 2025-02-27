WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PostComments AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
),
PostWithComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.RankScore,
        pc.CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
)
SELECT 
    pwc.PostId,
    pwc.Title,
    pwc.CreationDate,
    pwc.Score,
    pwc.ViewCount,
    pwc.RankScore,
    pwc.CommentCount,
    COALESCE(pwc.CommentCount, 0) AS EffectiveCommentCount,
    CASE 
        WHEN pwc.Score > 100 THEN 'High Score'
        WHEN pwc.Score BETWEEN 50 AND 100 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    STRING_AGG(DISTINCT CASE WHEN t.Id IS NOT NULL THEN t.TagName ELSE 'No Tags' END, ', ') AS AllTags
FROM 
    PostWithComments pwc
LEFT JOIN 
    LATERAL (
        SELECT 
            Tags.Id, 
            Tags.TagName 
        FROM 
            unnest(string_to_array(pwc.Tags, ',')) AS tag 
        JOIN 
            Tags ON Tags.TagName = TRIM(tag)
    ) t ON TRUE
WHERE 
    pwc.RankScore = 1
    OR pwc.CommentCount IS NULL
GROUP BY 
    pwc.PostId, pwc.Title, pwc.CreationDate, pwc.Score, pwc.ViewCount, pwc.RankScore, pwc.CommentCount
ORDER BY 
    pwc.Score DESC, 
    EffectiveCommentCount DESC
FETCH FIRST 100 ROWS ONLY;
