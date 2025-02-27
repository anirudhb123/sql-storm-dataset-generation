WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        (SELECT COUNT(*) FROM Posts WHERE ParentId = p.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
), 
RankedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.ViewCount,
        pd.CommentCount,
        pd.AnswerCount,
        RANK() OVER (ORDER BY pd.Score DESC, pd.ViewCount DESC) AS PostRank
    FROM 
        PostDetails pd
), 
RecentUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCreated,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        u.Id
)
SELECT 
    up.DisplayName AS UserName,
    ur.PostRank,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.AnswerCount,
    COALESCE(uv.UpVoteCount, 0) AS UserUpVoteCount,
    COALESCE(uv.DownVoteCount, 0) AS UserDownVoteCount,
    ruca.PostsCreated,
    ruca.LastPostDate
FROM 
    RankedPosts rp
JOIN 
    Users up ON up.Id IN (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    UserVoteStats uv ON up.Id = uv.UserId
JOIN 
    RecentUserActivity ruca ON up.Id = ruca.UserId
WHERE 
    rp.PostRank <= 50
ORDER BY 
    rp.PostRank, up.DisplayName;
