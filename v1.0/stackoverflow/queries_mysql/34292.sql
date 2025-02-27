
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        @rownum := IF(@prev_post_type = p.PostTypeId, @rownum + 1, 1) AS RowNum,
        @prev_post_type := p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS JOIN (SELECT @rownum := 0, @prev_post_type := NULL) r
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, CommentCount
    FROM 
        RankedPosts
    WHERE 
        RowNum <= 5 
),
UserPostInteractions AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        up.VoteCount,
        up.UpVotes,
        up.DownVotes,
        @user_rank := @user_rank + 1 AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        UserPostInteractions up ON u.Id = up.UserId
    LEFT JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
    CROSS JOIN (SELECT @user_rank := 0) r
    WHERE 
        u.Reputation > 1000 
    ORDER BY 
        up.VoteCount DESC, COALESCE(ub.BadgeCount, 0) DESC
)
SELECT 
    tp.Title AS PostTitle,
    tp.CreationDate AS PostDate,
    tp.Score AS PostScore,
    tp.CommentCount AS TotalComments,
    tu.DisplayName AS UserName,
    tu.BadgeCount AS UserBadges,
    tu.VoteCount AS TotalVotes,
    tu.UpVotes,
    tu.DownVotes
FROM 
    TopPosts tp
JOIN 
    TopUsers tu ON EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.Id = tp.PostId AND p.OwnerUserId = tu.UserId
    )
ORDER BY 
    tp.Score DESC, tu.VoteCount DESC;
