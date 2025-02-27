WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        SUM(vote.VoteTypeId = 2)::int AS UpVotes,
        SUM(vote.VoteTypeId = 3)::int AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgesCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes vote ON u.Id = vote.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostsCount, 
        CommentsCount, 
        UpVotes, 
        DownVotes, 
        BadgesCount, 
        LastPostDate,
        RANK() OVER (ORDER BY PostsCount DESC) AS RankByPosts,
        RANK() OVER (ORDER BY UpVotes - DownVotes DESC) AS RankByVotes
    FROM 
        UserActivity
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.ViewCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVotes,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        p.Id
)
SELECT 
    au.UserId, 
    au.DisplayName, 
    au.Reputation, 
    au.PostsCount, 
    au.CommentsCount, 
    au.UpVotes AS TotalUpVotes, 
    au.DownVotes AS TotalDownVotes,
    ps.PostId,
    ps.Score AS PostScore,
    ps.ViewCount AS PostViewCount,
    ps.UpVotes AS PostUpVotes,
    ps.DownVotes AS PostDownVotes,
    ps.Tags AS AssociatedTags
FROM 
    ActiveUsers au
LEFT JOIN 
    PostStats ps ON au.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId LIMIT 1)
WHERE 
    (au.RankByPosts <= 10 AND au.RankByVotes <= 10)
    OR (au.Reputation > 1000 AND au.LastPostDate > NOW() - INTERVAL '6 months')
ORDER BY 
    au.Reputation DESC, 
    ps.Score DESC
LIMIT 50;

-- Add additional results about post history that have been modified in the last month
WITH RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        p.Title,
        ph.PostHistoryTypeId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '1 month'
)
SELECT 
    au.UserId,
    au.DisplayName,
    rph.PostId,
    rph.Title,
    rph.UserId AS EditorUserId,
    rph.CreationDate,
    rph.Comment,
    CASE 
        WHEN rph.PostHistoryTypeId IN (10, 11) THEN 'Closure/Reopening'
        WHEN rph.PostHistoryTypeId IN (4, 5) THEN 'Title/Body Edit'
        ELSE 'Other' 
    END AS EditType
FROM 
    ActiveUsers au
JOIN 
    RecentPostHistory rph ON au.UserId = rph.UserId
WHERE 
    rph.rn = 1
ORDER BY 
    rph.CreationDate DESC
LIMIT 50;
