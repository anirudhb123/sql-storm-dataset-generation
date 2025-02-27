WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS ScoreRank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int)
    GROUP BY 
        p.Id, pt.Name, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        Score,
        ViewCount,
        AnswerCount,
        TagsList
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 5
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.TagsList,
    COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
    STRING_AGG(DISTINCT bh.Name, ', ') AS BadgesEarned
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON c.PostId = tp.PostId
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN 
    PostHistory ph ON ph.PostId = tp.PostId
LEFT JOIN 
    PostHistoryTypes bh ON ph.PostHistoryTypeId = bh.Id
GROUP BY 
    tp.PostId, tp.Title, tp.OwnerDisplayName, tp.CreationDate, 
    tp.Score, tp.ViewCount, tp.AnswerCount, tp.TagsList
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
