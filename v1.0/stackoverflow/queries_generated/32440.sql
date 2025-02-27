WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
),
PostWithComments AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
         FROM 
            Comments 
         GROUP BY 
            PostId) c ON rp.PostId = c.PostId
),
RecentBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date >= CURRENT_DATE - INTERVAL '30 days'  -- Badges awarded in the last month
    GROUP BY 
        b.UserId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(rb.BadgeCount, 0) AS RecentBadges,
        COALESCE(rb.BadgeNames, '') AS BadgeNames,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        RecentBadges rb ON u.Id = rb.UserId
)
SELECT 
    pwc.PostId,
    pwc.Title,
    pwc.OwnerDisplayName,
    us.DisplayName AS UserName,
    us.Reputation,
    us.RecentBadges,
    us.BadgeNames,
    pwc.CommentCount,
    pwc.CreationDate,
    pwc.ViewCount,
    COALESCE(v.UpVotes, 0) AS UpVotes,
    COALESCE(v.DownVotes, 0) AS DownVotes
FROM 
    PostWithComments pwc
JOIN 
    UserStatistics us ON pwc.OwnerDisplayName = us.DisplayName
LEFT JOIN 
    (SELECT 
        PostId, 
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
     FROM 
        Votes 
     GROUP BY 
        PostId) v ON pwc.PostId = v.PostId
WHERE 
    us.UserRank <= 100  -- Limiting to top 100 users by reputation
ORDER BY 
    pwc.ViewCount DESC, pwc.CommentCount DESC
LIMIT 50;  -- Limiting the result to a top 50 based on views and comments
