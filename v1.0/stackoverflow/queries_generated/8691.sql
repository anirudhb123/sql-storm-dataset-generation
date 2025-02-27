WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(SUM(c.Id IS NOT NULL), 0) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON tag IS NOT NULL
    LEFT JOIN Tags t ON LOWER(t.TagName) = LOWER(tag)
    WHERE p.CreationDate > '2023-01-01'
    GROUP BY p.Id
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.Score,
        ps.AnswerCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        ps.Tags,
        ps.Rank
    FROM PostStats ps
    WHERE ps.Rank <= 100
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    tp.Tags,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM TopPosts tp
JOIN Users u ON tp.PostId = u.Id
ORDER BY tp.Score DESC, tp.ViewCount DESC;
