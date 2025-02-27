
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM Posts p 
         JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
               UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
               UNION ALL SELECT 10) numbers ON CHAR_LENGTH(p.Tags) 
               -CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n-1) t ON TRUE
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        PostsCreated DESC
    LIMIT 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    pvc.UpVotes,
    pvc.DownVotes,
    rp.Tags,
    tu.DisplayName AS TopUserDisplayName,
    tu.PostsCreated,
    tu.TotalBadges
FROM 
    RecentPosts rp
LEFT JOIN 
    PostVoteCounts pvc ON rp.PostId = pvc.PostId
CROSS JOIN 
    (SELECT DisplayName, PostsCreated, TotalBadges FROM TopUsers) tu
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC
LIMIT 10;
