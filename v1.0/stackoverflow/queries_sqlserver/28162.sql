
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, p.PostTypeId, p.Score
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.CommentCount,
    fp.VoteCount,
    STRING_AGG(t.TagName, ', ') AS Tags,
    pht.Name AS PostHistoryTypeName
FROM 
    FilteredPosts fp
LEFT JOIN 
    Posts p ON fp.PostId = p.Id
CROSS APPLY (SELECT VALUE AS TagName FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')) AS t
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    fp.PostId, fp.Title, fp.OwnerDisplayName, fp.CreationDate, fp.CommentCount, fp.VoteCount, pht.Name
ORDER BY 
    fp.CreationDate DESC;
