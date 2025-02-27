
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        u.DisplayName AS Author,
        GROUP_CONCAT(t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags,
        COUNT(c.Id) AS CommentCount,
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
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '<', -1) AS TagName
         FROM 
         (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) n
         WHERE n.n <= (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '>', '')))) t ON TRUE
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Body,
    rp.Author,
    rp.Tags,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 5 AND (rp.UpVotes - rp.DownVotes) > 0
ORDER BY 
    rp.UpVotes DESC, rp.CreationDate ASC;
