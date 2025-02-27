WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        p.Title AS PostTitle,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS LatestChangeDate
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened posts
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ua.QuestionCount,
    ua.CommentCount,
    ua.UpVoteCount,
    ua.DownVoteCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    ps.CommentCount AS PostCommentCount,
    ps.UpVotes AS PostUpVotes,
    ps.DownVotes AS PostDownVotes,
    RANK() OVER (ORDER BY ua.QuestionCount DESC) AS UserRank,
    RANK() OVER (ORDER BY ps.UpVotes DESC) AS PostRank,
    COALESCE(rph.LatestChangeDate, p.LastActivityDate) AS LastActionDate
FROM 
    Users u
LEFT JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank = 1
LEFT JOIN 
    PostStatistics ps ON rp.PostId = ps.PostId
LEFT JOIN 
    RecentPostHistory rph ON rp.PostId = rph.PostId
WHERE 
    ua.QuestionCount > 0 OR ua.CommentCount > 0
ORDER BY 
    UserRank, PostRank;
