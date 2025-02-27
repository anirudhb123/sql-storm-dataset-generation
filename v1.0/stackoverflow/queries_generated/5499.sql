WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Tags,
        OwnerDisplayName,
        CommentCount,
        AnswerCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Tags,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.AnswerCount,
    tp.UpVotes,
    tp.DownVotes,
    COALESCE((SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = tp.PostId AND ph.PostHistoryTypeId IN (10, 11)), 0) AS ClosureCount
FROM 
    TopPosts tp
ORDER BY 
    tp.UpVotes DESC, 
    tp.CreationDate DESC;
