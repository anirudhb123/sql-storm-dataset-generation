WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        TotalUpVotes,
        TotalDownVotes,
        CommentCount,
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY (PostCount + TotalUpVotes - TotalDownVotes) DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    r.UserId,
    r.DisplayName,
    r.PostCount,
    r.TotalUpVotes,
    r.TotalDownVotes,
    r.CommentCount,
    r.BadgeCount
FROM 
    RankedUsers r
WHERE 
    r.Rank <= 10
ORDER BY 
    r.Rank;
