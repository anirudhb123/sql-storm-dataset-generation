
WITH PostsStats AS (
    SELECT 
        p.Id AS PostId,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVoteCount,
        AVG(IFNULL(TIMESTAMPDIFF(SECOND, p.CreationDate, p.LastActivityDate), 0)) AS AvgResponseTime
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, pt.Name
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(IF(b.Class = 1, b.Id, NULL)) AS GoldBadges,
        COUNT(IF(b.Class = 2, b.Id, NULL)) AS SilverBadges,
        COUNT(IF(b.Class = 3, b.Id, NULL)) AS BronzeBadges
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
