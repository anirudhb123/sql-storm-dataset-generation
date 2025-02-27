WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(b.Class) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 10 OR COUNT(DISTINCT c.Id) > 20
),
TopActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        CommentCount,
        UpVotes,
        DownVotes,
        BadgeCount,
        RANK() OVER (ORDER BY PostCount DESC, CommentCount DESC) AS ActivityRank
    FROM 
        UserActivity
)
SELECT 
    t.DisplayName,
    t.PostCount,
    t.CommentCount,
    t.UpVotes,
    t.DownVotes,
    t.BadgeCount
FROM 
    TopActiveUsers t
WHERE 
    t.ActivityRank <= 10
ORDER BY 
    t.PostCount DESC, t.CommentCount DESC;
