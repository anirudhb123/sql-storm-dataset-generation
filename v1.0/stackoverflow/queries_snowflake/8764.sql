
WITH PostsStats AS (
    SELECT 
        p.Id AS PostId,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        SUM(IFF(v.VoteTypeId = 2, 1, 0)) AS UpVotes,
        SUM(IFF(v.VoteTypeId = 3, 1, 0)) AS DownVotes,
        COUNT(IFF(v.VoteTypeId = 2, 1, NULL)) AS UpVoteCount,
        COUNT(IFF(v.VoteTypeId = 3, 1, NULL)) AS DownVoteCount,
        AVG(COALESCE(DATEDIFF(EPOCH_SECOND, p.CreationDate, p.LastActivityDate), 0)) AS AvgResponseTime
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
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
