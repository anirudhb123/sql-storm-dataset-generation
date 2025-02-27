WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.Id IS NOT NULL AND vt.Name = 'UpMod') AS Upvotes,
        SUM(v.Id IS NOT NULL AND vt.Name = 'DownMod') AS Downvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.Id IS NOT NULL AND vt.Name = 'UpMod') AS Upvotes,
        SUM(v.Id IS NOT NULL AND vt.Name = 'DownMod') AS Downvotes,
        MAX(p.CreationDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        p.Id, p.Title, pt.Name
)
SELECT 
    us.DisplayName AS UserName,
    us.Reputation,
    us.PostCount,
    us.CommentCount AS UserCommentCount,
    us.BadgeCount,
    us.Upvotes AS UserUpvotes,
    us.Downvotes AS UserDownvotes,
    ps.PostId,
    ps.Title AS PostTitle,
    ps.PostType,
    ps.CommentCount AS PostCommentCount,
    ps.Upvotes AS PostUpvotes,
    ps.Downvotes AS PostDownvotes,
    ps.LastActivityDate
FROM 
    UserStatistics us
JOIN 
    PostStatistics ps ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)
ORDER BY 
    us.Reputation DESC, ps.LastActivityDate DESC
LIMIT 10;
