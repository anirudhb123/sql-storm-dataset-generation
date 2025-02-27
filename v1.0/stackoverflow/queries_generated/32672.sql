WITH RECURSIVE UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.UpVotes,
        u.DownVotes,
        0 AS TotalVotes,
        0 AS TotalBounty
    FROM 
        Users u
    WHERE 
        u.Reputation > 100 -- Only consider users with significant reputation

    UNION ALL

    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.UpVotes,
        u.DownVotes,
        uv.TotalVotes + COUNT(v.Id) AS TotalVotes,
        uv.TotalBounty + COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    JOIN 
        UserVoteStats uv ON u.Id = uv.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.UpVotes, u.DownVotes, uv.TotalVotes
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        p.CreationDate,
        p.Score,
        COALESCE(b.Count, 0) AS BadgeCount,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(Id) AS Count 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON b.UserId = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(Id) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON c.PostId = p.Id
),
VoteDetails AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    ud.UserId,
    ud.DisplayName,
    ud.Reputation,
    pd.PostId,
    pd.Title,
    pd.PostType,
    pd.CreationDate,
    pd.Score,
    vd.VoteCount,
    vd.UpvoteCount,
    vd.DownvoteCount,
    ud.TotalVotes,
    ud.TotalBounty
FROM 
    UserVoteStats ud
JOIN 
    PostDetails pd ON pd.PostId IN (SELECT PostId FROM Votes v WHERE v.UserId = ud.UserId) -- Posts voted on by the user
JOIN 
    VoteDetails vd ON vd.PostId = pd.PostId
WHERE 
    ud.TotalVotes > 0 -- Only include users who have voted
ORDER BY 
    ud.TotalVotes DESC, 
    pd.Score DESC
LIMIT 100;
