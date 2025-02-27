WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER(WHERE vt.Name = 'UpMod') AS UpvoteCount,
        COUNT(v.Id) FILTER(WHERE vt.Name = 'DownMod') AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        p.PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.OwnerDisplayName,
        p.CommentCount,
        p.UpvoteCount,
        p.DownvoteCount,
        CASE 
            WHEN p.UpvoteCount - p.DownvoteCount > 0 THEN 'Positive'
            WHEN p.UpvoteCount - p.DownvoteCount < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment
    FROM 
        RankedPosts p
    WHERE 
        p.rn = 1
    ORDER BY 
        p.UpvoteCount - p.DownvoteCount DESC 
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.Tags,
    to_char(tp.CreationDate, 'YYYY-MM-DD HH24:MI:SS') AS CreationDate,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.DownvoteCount,
    tp.VoteSentiment,
    ph.UserDisplayName AS LastEditor,
    ph.CreationDate AS LastEditDate,
    ph.Comment AS EditComment,
    ph.Text AS EditText
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId 
                   AND ph.CreationDate = (
                       SELECT MAX(CreationDate) 
                       FROM PostHistory 
                       WHERE PostId = tp.PostId
                   )
ORDER BY 
    tp.UpvoteCount DESC;
