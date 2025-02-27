WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS t ON t.TagName = t.TagName
    GROUP BY 
        p.Id, u.Id
),
FilteredPosts AS (
    SELECT 
        PostId, 
        Title, 
        CreationDate, 
        ViewCount, 
        Score, 
        CommentCount, 
        AnswerCount, 
        RankByUser, 
        OwnerDisplayName, 
        OwnerReputation, 
        TagsList
    FROM 
        RankedPosts
    WHERE 
        RankByUser = 1 
        AND ViewCount > 50 
        AND CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.CommentCount,
    fp.AnswerCount,
    fp.OwnerDisplayName,
    fp.OwnerReputation,
    fp.TagsList
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.ViewCount DESC
LIMIT 50;
