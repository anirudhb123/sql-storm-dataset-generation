WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2023-01-01'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.UpVotes,
        ua.DownVotes,
        ua.CommentCount,
        ua.BadgeCount,
        RANK() OVER (ORDER BY ua.UpVotes DESC) AS UserRank
    FROM 
        UserActivity ua
    WHERE 
        ua.CommentCount > 0
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount,
    au.DisplayName AS TopUser,
    au.UpVotes,
    au.DownVotes,
    au.CommentCount,
    au.BadgeCount
FROM 
    TopPosts tp
JOIN 
    ActiveUsers au ON tp.PostId IN (SELECT PostId FROM Votes v WHERE v.UserId = au.UserId)
WHERE 
    au.UserRank <= 5
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
