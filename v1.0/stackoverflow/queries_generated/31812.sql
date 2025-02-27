WITH RECURSIVE UserPostCount AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
), 
RecentPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        COALESCE(u.DisplayName, 'Deleted User') AS UserDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
), 
TopPosts AS (
    SELECT 
        r.* 
    FROM 
        RecentPostStats r
    WHERE 
        r.rn <= 5
)

SELECT 
    t.UserDisplayName,
    COUNT(t.PostId) AS TotalPosts,
    AVG(upvotes) AS AvgUpVotes,
    AVG(downvotes) AS AvgDownVotes,
    COALESCE(u.Reputation, 0) AS Reputation,
    t.CreationDate,
    SUM(b.Class) AS TotalBadges,
    STRING_AGG(DISTINCT CONCAT('Top Post: ', t.Title), '; ') AS TopPosts
FROM 
    UserPostCount UPC
JOIN 
    (SELECT 
        t.UserDisplayName,
        t.PostId,
        t.UpVotes AS upvotes,
        t.DownVotes AS downvotes,
        t.CreationDate,
        b.UserId
     FROM 
        TopPosts t
     LEFT JOIN 
        Badges b ON t.UserDisplayName = b.UserId
    ) t ON UPC.OwnerUserId = t.UserId
LEFT JOIN 
    Users u ON u.Id = t.UserId
GROUP BY 
    t.UserDisplayName, t.CreationDate, u.Reputation
ORDER BY 
    TotalPosts DESC, Reputation DESC;
