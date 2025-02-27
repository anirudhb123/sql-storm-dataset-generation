
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        t.TagName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    OUTER APPLY 
        (SELECT DISTINCT value AS TagName FROM STRING_SPLIT(p.Tags, '>')) t
    WHERE 
        p.CreationDate > '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp 
    WHERE 
        rp.Rank <= 5
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.ViewCount,
        tp.OwnerDisplayName,
        STRING_AGG(DISTINCT tp.TagName, ', ') AS Tags
    FROM 
        TopPosts tp
    GROUP BY 
        tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.OwnerDisplayName
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.Tags,
    bh.Name AS BadgeName,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
FROM 
    PostDetails pd
LEFT JOIN 
    Comments c ON pd.PostId = c.PostId
LEFT JOIN 
    Badges bh ON bh.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pd.PostId)
LEFT JOIN 
    Votes v ON pd.PostId = v.PostId
GROUP BY 
    pd.PostId, pd.Title, pd.Score, pd.ViewCount, pd.OwnerDisplayName, pd.Tags, bh.Name
ORDER BY 
    pd.ViewCount DESC, pd.Score DESC;
