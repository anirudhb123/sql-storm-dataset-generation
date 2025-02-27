WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
), 
RecentPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId, 
        COUNT(c.Id) AS CommentCount,
        AVG(v.VoteTypeId = 2) AS UpVotes,
        AVG(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id
), 
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        u.DisplayName,
        Coalesce(rp.UpVotes, 0) AS UpVotes,
        Coalesce(rp.DownVotes, 0) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        CASE 
            WHEN rp.CommentCount > 5 THEN 'Highly Commented'
            WHEN rp.CommentCount BETWEEN 3 AND 5 THEN 'Moderately Commented'
            ELSE 'Few Comments'
        END AS CommentCategory
    FROM 
        RecentPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, u.DisplayName
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.DisplayName,
    ps.UpVotes,
    ps.DownVotes,
    ps.BadgeCount,
    ps.CommentCategory,
    CASE 
        WHEN ps.UpVotes > ps.DownVotes THEN 'Positive'
        WHEN ps.UpVotes < ps.DownVotes THEN 'Negative'
        ELSE 'Neutral' 
    END AS Sentiment
FROM 
    PostStatistics ps
JOIN 
    UserReputation ur ON ps.DisplayName = ur.DisplayName
WHERE 
    ur.Rank <= 50
ORDER BY 
    ps.CommentCategory, ps.UpVotes DESC;
