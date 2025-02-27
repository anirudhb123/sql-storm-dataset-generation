WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        MAX(p.CreationDate) AS LatestActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
    ORDER BY 
        AvgReputation DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ps.LatestActivityDate,
        tu.DisplayName AS TopUser
    FROM 
        PostStatistics ps
    JOIN 
        TopUsers tu ON ps.UpVotes > 5 -- Only consider posts with more than 5 upvotes
)
SELECT 
    pd.Title,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.LatestActivityDate,
    pd.TopUser
FROM 
    PostDetails pd
WHERE 
    pd.LatestActivityDate BETWEEN NOW() - INTERVAL '30 days' AND NOW()
ORDER BY 
    pd.UpVotes DESC, pd.CommentCount DESC;
