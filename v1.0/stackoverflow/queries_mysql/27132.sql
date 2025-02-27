
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVoteCount,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        rp.PostRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.ViewCount >= 1000  
        AND rp.UpVoteCount - rp.DownVoteCount > 0  
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    GROUP_CONCAT(CONVERT(SUBSTRING_INDEX(SUBSTRING_INDEX(fp.Tags, '<>', n.n), '<>', -1) USING utf8) SEPARATOR ', ') AS ProcessedTags,
    fp.ViewCount,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.PostRank
FROM 
    FilteredPosts fp
JOIN 
    (SELECT a.N FROM 
        (SELECT 1 AS N UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) a
    ) n ON CHAR_LENGTH(fp.Tags) - CHAR_LENGTH(REPLACE(fp.Tags, '<>', '')) >= n.N - 1
WHERE 
    fp.PostRank <= 100  
GROUP BY 
    fp.PostId, fp.Title, fp.Body, fp.Tags, fp.ViewCount, fp.OwnerDisplayName, fp.CommentCount, fp.UpVoteCount, fp.DownVoteCount, fp.PostRank
ORDER BY 
    fp.ViewCount DESC;
