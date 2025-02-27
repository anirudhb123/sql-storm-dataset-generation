
WITH TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(b.Id) AS BadgeCount,
        AVG(CAST(u.Reputation AS FLOAT)) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST(DATEADD(DAY, -30, '2024-10-01 12:34:56') AS DATETIME)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
PostDetails AS (
    SELECT 
        ap.PostId,
        ap.Title,
        ap.CreationDate,
        ap.Score,
        ap.CommentCount,
        ap.VoteCount,
        tu.DisplayName,
        tu.TotalUpVotes,
        tu.TotalDownVotes,
        tu.BadgeCount,
        tu.AvgReputation
    FROM 
        ActivePosts ap
    JOIN 
        TopUsers tu ON ap.Score > 10
    ORDER BY 
        ap.Score DESC, ap.VoteCount DESC
)
SELECT TOP 100
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.CommentCount,
    pd.VoteCount,
    pd.DisplayName,
    pd.TotalUpVotes,
    pd.TotalDownVotes,
    pd.BadgeCount,
    pd.AvgReputation
FROM 
    PostDetails pd
WHERE 
    pd.CommentCount > 5
ORDER BY 
    pd.CreationDate DESC;
