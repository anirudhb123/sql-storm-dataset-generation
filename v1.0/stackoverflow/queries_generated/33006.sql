WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS HistoryDate,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS RN
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= (NOW() - INTERVAL '1 year') -- Posts created in the last year
), 
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostsWithVoteCount AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.BadgeCount,
    u.TotalBounties,
    u.UpVotes,
    u.DownVotes,
    pp.PostId,
    pp.Title,
    pp.VoteCount,
    RPH.HistoryDate,
    RPH.PostHistoryTypeId,
    RPH.Comment
FROM 
    UserStatistics u
LEFT JOIN 
    PostsWithVoteCount pp ON u.UserId = pp.PostId AND RPH.RN = 1
LEFT JOIN 
    RecursivePostHistory RPH ON pp.PostId = RPH.PostId
WHERE 
    (u.UpVotes > u.DownVotes OR u.BadgeCount > 0)
    AND RPH.PostHistoryTypeId NOT IN (10, 12) -- Excluding closed or deleted posts
ORDER BY 
    u.BadgeCount DESC, 
    pp.VoteCount DESC;

