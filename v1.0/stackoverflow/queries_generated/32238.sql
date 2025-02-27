WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS ActivityRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
UserIdWithPostVotes AS (
    SELECT 
        v.UserId,
        p.PostTypeId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    INNER JOIN 
        Posts p ON v.PostId = p.Id
    GROUP BY 
        v.UserId, p.PostTypeId
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
        COALESCE(vs.DownVotes, 0) AS TotalDownVotes,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY COALESCE(vs.UpVotes, 0) DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        UserIdWithPostVotes vs ON p.OwnerUserId = vs.UserId
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.PostCount,
    ua.CommentCount,
    ua.BadgeCount,
    ps.Title,
    ps.CreationDate,
    ps.LastActivityDate,
    ps.TotalUpVotes,
    ps.TotalDownVotes,
    CASE 
        WHEN ps.VoteRank <= 5 THEN 'Top Post'
        ELSE 'Regular Post'
    END AS PostRanking
FROM 
    UserActivity ua
JOIN 
    PostSummary ps ON ua.UserId = ps.OwnerUserId
WHERE 
    ps.CreationDate >= NOW() - INTERVAL '1 year'
ORDER BY 
    ua.PostCount DESC, 
    ps.TotalUpVotes DESC;
