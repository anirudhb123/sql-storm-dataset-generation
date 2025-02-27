WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.ViewCount,
        ps.Score,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        us.UserId,
        us.DisplayName AS UserDisplayName,
        us.BadgeCount,
        us.TotalUpVotes AS UserTotalUpVotes,
        us.TotalDownVotes AS UserTotalDownVotes,
        us.AvgReputation
    FROM 
        PostStatistics ps
        JOIN Users u ON ps.UserId = u.Id
        JOIN UserStatistics us ON u.Id = us.UserId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    CommentCount,
    UpVotes,
    DownVotes,
    UserId,
    UserDisplayName,
    BadgeCount,
    UserTotalUpVotes,
    UserTotalDownVotes,
    AvgReputation
FROM 
    PostSummary
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 100;
