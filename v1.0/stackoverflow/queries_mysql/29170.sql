
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS TagName
         FROM 
         (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
          UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) t ON TRUE
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
MostActiveUser AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostId) AS NumberOfPosts
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5 
    GROUP BY 
        OwnerDisplayName
    ORDER BY 
        NumberOfPosts DESC
    LIMIT 10
),
PostStats AS (
    SELECT 
        p.PostId,
        p.Title,
        p.Score,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        p.CommentCount,
        p.Tags
    FROM 
        RankedPosts p
    LEFT JOIN 
        Votes v ON p.PostId = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        p.OwnerDisplayName IN (SELECT OwnerDisplayName FROM MostActiveUser)
    GROUP BY 
        p.PostId, p.Title, p.Score, p.CommentCount, p.Tags
)
SELECT 
    ps.Title,
    ps.Score,
    ps.UpVotes,
    ps.DownVotes,
    ps.CommentCount,
    ps.Tags
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC,
    ps.UpVotes DESC,
    ps.CommentCount DESC;
