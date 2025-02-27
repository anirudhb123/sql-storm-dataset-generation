
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END) AS DeletionVotes,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT 
            p.Id,
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
        INNER JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        ) AS t ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, p.PostTypeId
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.DeletionVotes,
        ps.Tags,
        RANK() OVER (ORDER BY ps.UpVotes - ps.DownVotes DESC) AS Rank
    FROM 
        PostStats ps
    WHERE 
        ps.PostTypeId = 1 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.DeletionVotes,
    tp.Tags,
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.PostCount,
    ur.BadgeCount
FROM 
    TopPosts tp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
JOIN 
    UserReputation ur ON u.Id = ur.UserId
WHERE 
    tp.Rank <= 10 
ORDER BY 
    tp.Rank;
