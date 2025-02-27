WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - interval '1 year'
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, u.DisplayName
),
TopPosts AS (
    SELECT 
        pd.*,
        ROW_NUMBER() OVER (ORDER BY pd.Score DESC, pd.ViewCount DESC) AS OverallRank
    FROM 
        PostDetails pd
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.VoteCount,
    tp.OverallRank
FROM 
    TopPosts tp
WHERE 
    tp.OverallRank <= 10
ORDER BY 
    tp.OverallRank;
