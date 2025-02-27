WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1 -- Questions
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT *
    FROM RankedPosts
    WHERE Rank <= 10
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.OwnerDisplayName,
        tp.CommentCount,
        tp.VoteCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM TopPosts tp
    LEFT JOIN Posts p ON tp.PostId = p.Id
    LEFT JOIN Tags t ON t.Id IN (SELECT unnest(string_to_array(p.Tags, '>'))::int)
    GROUP BY tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.OwnerDisplayName, tp.CommentCount, tp.VoteCount
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.VoteCount,
    pd.Tags,
    COALESCE(b.Name, 'No Badge') AS UserBadge
FROM PostDetails pd
LEFT JOIN Badges b ON pd.PostId = b.UserId AND b.Class = 1 -- Gold badges
ORDER BY pd.Score DESC, pd.CreationDate DESC;
