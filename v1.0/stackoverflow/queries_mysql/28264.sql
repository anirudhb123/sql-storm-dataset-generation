
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        AVG(v.VoteTypeId) AS AverageVoteType,
        GROUP_CONCAT(t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT 
            p.Id AS PostId, 
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '<', -1) AS TagName
        FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers 
        JOIN 
            Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
        ) AS t ON p.Id = t.PostId
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR) 
    GROUP BY 
        p.Id, u.DisplayName, p.Body, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.*,
        RANK() OVER (ORDER BY rp.CommentCount DESC, rp.AverageVoteType DESC) AS Rank
    FROM 
        RankedPosts rp
    WHERE 
        CHAR_LENGTH(rp.Tags) > 0 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Owner,
    fp.CommentCount,
    fp.AverageVoteType,
    fp.Tags,
    CASE 
        WHEN fp.Rank <= 10 THEN 'Top 10'
        WHEN fp.Rank <= 20 THEN 'Top 20'
        ELSE 'Below Top 20'
    END AS RankCategory
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Rank
LIMIT 50;
