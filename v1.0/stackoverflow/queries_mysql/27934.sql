
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        GROUP_CONCAT(DISTINCT u.DisplayName SEPARATOR ', ') AS ContributingUsers
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    LEFT JOIN 
        Users u ON v.UserId = u.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL 30 DAY 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.Tags, pt.Name
),
PostTagStats AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts p
    JOIN 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        Tag
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.Tags,
    rp.Rank,
    rp.ContributingUsers,
    pts.PostCount AS TagPostCount
FROM 
    RankedPosts rp
JOIN 
    PostTagStats pts ON pts.Tag = SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', n.n), '><', -1)
JOIN 
    (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
     UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
ON CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, '><', '')) >= n.n - 1
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.Rank, rp.Score DESC;
