WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        SUM(vote.VoteTypeId = 2) AS UpVotes,
        SUM(vote.VoteTypeId = 3) AS DownVotes
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Comments c ON u.Id = c.UserId
        LEFT JOIN Votes vote ON u.Id = vote.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
        LEFT JOIN PostsTags pt ON p.Id = pt.PostId
        LEFT JOIN Tags t ON pt.TagId = t.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
CombinedStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostsCount,
        us.CommentsCount,
        us.UpVotes,
        us.DownVotes,
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Tags
    FROM 
        UserStats us
        LEFT JOIN RecentPosts rp ON us.UserId = rp.OwnerUserId
)
SELECT 
    c.UserId,
    c.DisplayName,
    c.Reputation,
    c.PostsCount,
    c.CommentsCount,
    c.UpVotes,
    c.DownVotes,
    c.PostId,
    c.Title,
    c.CreationDate,
    c.Score,
    c.ViewCount,
    c.Tags
FROM 
    CombinedStats c
WHERE 
    c.Reputation > 1000
ORDER BY 
    c.Reputation DESC, c.PostsCount DESC
LIMIT 10;
