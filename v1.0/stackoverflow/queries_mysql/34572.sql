
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS tag_name
         FROM 
           (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
            UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ROW_NUMBER() OVER (ORDER BY ua.VoteCount DESC) AS UserRank
    FROM 
        UserActivity ua
    WHERE 
        ua.VoteCount > 0
),
RecentActivity AS (
    SELECT 
        up.PostId,
        up.Title,
        up.CreationDate,
        up.Score,
        up.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN pv.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN pv.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        RankedPosts up
    LEFT JOIN 
        Users u ON up.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON up.PostId = c.PostId
    LEFT JOIN 
        Votes pv ON up.PostId = pv.PostId
    WHERE 
        up.rn = 1
    GROUP BY 
        up.PostId, up.Title, up.CreationDate, up.Score, up.ViewCount, u.DisplayName
)
SELECT 
    ra.PostId,
    ra.Title,
    ra.CreationDate,
    ra.Score,
    ra.ViewCount,
    ra.OwnerDisplayName,
    ra.CommentCount,
    tu.DisplayName AS TopUser,
    tu.UserRank,
    COALESCE(ra.TotalUpVotes, 0) AS TotalUpVotes,
    COALESCE(ra.TotalDownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN ra.Score IS NULL OR ra.Score < 10 THEN 'Low Score'
        WHEN ra.Score BETWEEN 10 AND 50 THEN 'Medium Score'
        ELSE 'High Score'
    END AS ScoreCategory
FROM 
    RecentActivity ra
LEFT JOIN 
    TopUsers tu ON ra.OwnerDisplayName = tu.DisplayName
WHERE 
    tu.UserRank <= 10 OR tu.UserRank IS NULL
ORDER BY 
    ra.Score DESC, ra.ViewCount DESC
LIMIT 50;
