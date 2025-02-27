WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(b.Class), 0) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        p.Id,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
UserTopPosts AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        ROW_NUMBER() OVER (PARTITION BY ur.UserId ORDER BY rp.Score DESC) AS UserPostRank
    FROM 
        UserReputation ur
    JOIN 
        RankedPosts rp ON ur.UserId = rp.PostId
    LEFT JOIN 
        PostStatistics ps ON rp.PostId = ps.Id
)
SELECT 
    u.DisplayName,
    up.PostId,
    up.Title,
    up.CreationDate,
    up.Score,
    COALESCE(up.CommentCount, 0) AS CommentCount,
    COALESCE(up.UpVotes, 0) AS UpVotes,
    COALESCE(up.DownVotes, 0) AS DownVotes,
    CASE WHEN ur.TotalBadges > 5 THEN 'High Achiever' WHEN ur.TotalBadges BETWEEN 1 AND 5 THEN 'Achiever' ELSE 'Newcomer' END AS UserLevel
FROM 
    UserReputation ur
JOIN 
    UserTopPosts up ON ur.UserId = up.UserId
WHERE 
    up.UserPostRank <= 5
    AND (ur.Reputation > 100 OR ur.TotalBadges > 0)
ORDER BY 
    ur.Reputation DESC, up.Score DESC;

-- Additional query to test interesting cases using outer joins and NULL logic.
SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    COALESCE(ph.Comment, 'No history comments') AS HistoryComment,
    CASE 
        WHEN ph.PostHistoryTypeId IS NULL THEN 'Never modified'
        WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
        ELSE 'Edited'
    END AS PostState,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11, 12, 13) 
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
WHERE 
    u.Reputation < 50
GROUP BY 
    u.DisplayName, p.Title, ph.Comment, ph.PostHistoryTypeId
ORDER BY 
    u.DisplayName;
