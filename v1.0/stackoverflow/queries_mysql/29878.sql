
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '<', -1)) AS tag 
         FROM Posts p 
         CROSS JOIN (SELECT @rownum := @rownum + 1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t1, 
         (SELECT @rownum := 0) r) n 
         WHERE n.n <= 1 + LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '>', ''))) n
    ) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
), 
PostScores AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        TotalComments,
        UpVotes - DownVotes AS NetVotes,
        @row_number := @row_number + 1 AS Ranking
    FROM 
        RankedPosts, (SELECT @row_number := 0) r
    ORDER BY 
        (UpVotes - DownVotes) DESC, TotalComments DESC
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.TotalComments,
    ps.NetVotes,
    ps.Ranking,
    rp.Tags
FROM 
    PostScores ps
JOIN 
    RankedPosts rp ON ps.PostId = rp.PostId
WHERE 
    ps.Ranking <= 10;
