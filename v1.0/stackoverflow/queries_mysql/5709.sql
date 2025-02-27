
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1) tag
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
               UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
               UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         WHERE CHAR_LENGTH(p.Tags) -CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag.tag = t.TagName
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    ORDER BY 
        u.Reputation DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.AnswerCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.Tags,
    tu.DisplayName AS TopUser,
    tu.Reputation,
    tu.BadgeCount,
    tu.TotalViews
FROM 
    RecentPosts rp
JOIN 
    TopUsers tu ON rp.ViewCount = (SELECT MAX(ViewCount) FROM RecentPosts)
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 5;
