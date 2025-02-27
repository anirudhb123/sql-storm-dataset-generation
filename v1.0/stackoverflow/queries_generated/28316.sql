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
        Votes v ON v.PostId = p.Id AND v.VoteTypeId = 2 -- UpMod
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, u.DisplayName
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
    string_agg(DISTINCT t.TagName, ', ') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    Posts p ON p.Id = tp.PostId
LEFT JOIN 
    Tags t ON t.TagName = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><'))
GROUP BY 
    tp.PostId, tp.Title, tp.UserDisplayName, tp.CommentCount, tp.UpVoteCount
ORDER BY 
    tp.UpVoteCount DESC;
