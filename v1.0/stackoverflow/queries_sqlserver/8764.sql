
WITH PostsStats AS (
    SELECT 
        p.Id AS PostId,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        AVG(DATEDIFF(SECOND, p.CreationDate, p.LastActivityDate)) AS AvgResponseTime
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, CAST('2024-10-01 12:34:56' AS DATETIME))
    GROUP BY 
        p.Id, pt.Name
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ps.PostId,
    ps.PostType,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ps.AvgResponseTime
FROM 
    PostsStats ps
LEFT JOIN 
    Users u ON ps.PostId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
ORDER BY 
    ps.AvgResponseTime DESC, ps.CommentCount DESC;
