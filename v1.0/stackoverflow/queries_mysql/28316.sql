
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS UserDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS UpVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 2 
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.UserDisplayName,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1
    ORDER BY 
        rp.UpVoteCount DESC
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.UserDisplayName,
    tp.CommentCount,
    tp.UpVoteCount,
    GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    Posts p ON p.Id = tp.PostId
LEFT JOIN 
    Tags t ON FIND_IN_SET(t.TagName, SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2)) > 0
GROUP BY 
    tp.PostId, tp.Title, tp.UserDisplayName, tp.CommentCount, tp.UpVoteCount
ORDER BY 
    tp.UpVoteCount DESC;
