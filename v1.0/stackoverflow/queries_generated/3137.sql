WITH UserScore AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        (u.UpVotes - u.DownVotes) AS NetVotes, 
        ROW_NUMBER() OVER (ORDER BY (u.UpVotes - u.DownVotes) DESC) AS Rank,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.UpVotes, u.DownVotes
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate)) AS AgeInSeconds,
        p.ViewCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '><')) AS t(TagName) ON TRUE
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
PostStatistics AS (
    SELECT 
        p.UserId, 
        COUNT(DISTINCT c.Id) AS CommentCount, 
        SUM(v.BountyAmount) AS TotalBounty, 
        AVG(v.VoteTypeId) AS AvgVoteType
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.NetVotes,
    us.Rank,
    us.BadgeCount,
    rp.PostId,
    rp.Title,
    rp.AgeInSeconds,
    rp.ViewCount,
    COALESCE(ps.CommentCount, 0) AS CommentCount,
    COALESCE(ps.TotalBounty, 0) AS TotalBounty,
    COALESCE(ps.AvgVoteType, 0) AS AvgVoteType
FROM 
    UserScore us
LEFT JOIN 
    RecentPosts rp ON us.UserId = rp.UserId
LEFT JOIN 
    PostStatistics ps ON us.UserId = ps.UserId
WHERE 
    us.NetVotes > 0
ORDER BY 
    us.Rank, rp.CreationDate DESC
LIMIT 50;

