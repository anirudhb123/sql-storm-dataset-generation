WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
RecentPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.UpVotes > rp.DownVotes THEN 'Positive'
            WHEN rp.UpVotes < rp.DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5 -- Get only the last 5 posts per user
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    rp.PostId,
    rp.Title,
    rp.AnswerCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.VoteSentiment
FROM 
    Users u
LEFT JOIN 
    RecentPosts rp ON u.Id = rp.OwnerUserId
WHERE 
    u.Reputation > 1000 -- Only users with high reputation
ORDER BY 
    u.Reputation DESC, 
    rp.CreationDate DESC
LIMIT 20;

-- Additional Check for Null Logic
SELECT 
    COUNT(*) AS HighRepUsers,
    SUM(CASE WHEN rp.VoteSentiment IS NULL THEN 1 ELSE 0 END) AS NullSentimentCount
FROM 
    Users u
LEFT JOIN 
    RecentPosts rp ON u.Id = rp.OwnerUserId
WHERE 
    u.Reputation > 1000;
