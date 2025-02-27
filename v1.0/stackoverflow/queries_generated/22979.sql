WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostVoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    u.DisplayName AS OwnerName,
    u.TotalBadgeClass,
    (
        SELECT 
            COUNT(DISTINCT l.RelatedPostId) 
        FROM 
            PostLinks l 
        WHERE 
            l.PostId = p.PostId
    ) AS RelatedPostsCount,
    COALESCE(v.Upvotes, 0) AS Upvotes,
    COALESCE(v.Downvotes, 0) AS Downvotes,
    COALESCE(v.TotalVotes, 0) AS TotalVotes,
    CASE 
        WHEN p.Score < 0 THEN 'Negative'
        WHEN p.Score > 0 THEN 'Positive'
        ELSE 'Neutral'
    END AS ScoreCategory,
    CASE
        WHEN p.CreationDate <= CURRENT_DATE - INTERVAL '30 days' THEN 'Old Post'
        ELSE 'Recent Post'
    END AS PostAgeCategory
FROM 
    RankedPosts p
JOIN 
    UserReputation u ON p.OwnerUserId = u.UserId
LEFT JOIN 
    PostVoteStats v ON p.PostId = v.PostId
WHERE 
    p.OwnerPostRank = 1
    AND u.Reputation > 500
ORDER BY 
    p.Score DESC, p.CreationDate DESC;
