WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.PostTypeId = 1 AND  -- Only questions
        p.CreationDate > NOW() - INTERVAL '1 year'  -- Posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.OwnerUserId
),
PostStats AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        CreationDate,
        CommentCount,
        UpVotes,
        DownVotes,
        UserPostRank
    FROM 
        RankedPosts
    WHERE 
        UserPostRank <= 5  -- Keep top 5 posts per user
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    COUNT(DISTINCT ph.Id) AS EditCount,  -- Count of edits per post
    MAX(ph.CreationDate) AS LastEditDate  -- Date of the last edit
FROM 
    PostStats ps
JOIN 
    Users u ON ps.OwnerUserId = u.Id
LEFT JOIN 
    PostHistory ph ON ps.PostId = ph.PostId
GROUP BY 
    ps.PostId, ps.Title, ps.ViewCount, ps.CommentCount, ps.UpVotes, ps.DownVotes, u.DisplayName, u.Reputation
ORDER BY 
    ps.ViewCount DESC, ps.UpVotes DESC  -- Sort by view count and up votes
LIMIT 100;  -- Limit to 100 results
