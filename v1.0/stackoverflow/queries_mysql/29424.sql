
WITH RankedPostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.ViewCount, p.Score, u.DisplayName
),

FilteredPosts AS (
    SELECT 
        rps.PostId,
        rps.Title,
        rps.Body,
        rps.ViewCount,
        rps.Score,
        rps.OwnerDisplayName,
        rps.CommentCount,
        rps.UpVotes,
        rps.DownVotes
    FROM 
        RankedPostStatistics rps
    WHERE 
        rps.PostRank <= 10 
)

SELECT 
    f.Title,
    f.ViewCount,
    f.Score,
    f.CommentCount,
    f.UpVotes,
    f.DownVotes,
    f.OwnerDisplayName,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
FROM 
    FilteredPosts f
LEFT JOIN 
    (SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName
     FROM 
        Posts p
     JOIN 
        (SELECT 
            @row := @row + 1 AS n 
         FROM 
            (SELECT @row := 0) r, 
            (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) n
        ) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    ) AS t ON f.PostId = p.Id
GROUP BY 
    f.PostId, f.Title, f.ViewCount, f.Score, f.CommentCount, f.UpVotes, f.DownVotes, f.OwnerDisplayName
ORDER BY 
    f.Score DESC, f.ViewCount DESC;
