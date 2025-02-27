WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),

RecentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        DENSE_RANK() OVER (ORDER BY u.CreationDate DESC) AS RecentRank
    FROM 
        Users u
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '1 year'
),

PostVotes AS (
    SELECT
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 WHEN vt.Name = 'DownMod' THEN -1 ELSE 0 END) AS VoteScore
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),

PostDetails AS (
    SELECT
        rp.Title,
        rp.CreationDate,
        rp.Score,
        pu.DisplayName,
        pu.Reputation,
        COALESCE(pv.VoteScore, 0) AS TotalVotes
    FROM 
        RankedPosts rp
    JOIN 
        Users pu ON rp.OwnerUserId = pu.Id
    LEFT JOIN 
        PostVotes pv ON rp.Id = pv.PostId
    WHERE 
        rp.PostRank = 1
)

SELECT 
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.DisplayName,
    pd.Reputation,
    pd.TotalVotes,
    CASE 
        WHEN pd.TotalVotes > 0 THEN 'Positively Received'
        WHEN pd.TotalVotes < 0 THEN 'Negatively Received'
        ELSE 'Neutral'
    END AS VoteSentiment,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.Id) AS CommentCount
FROM 
    PostDetails pd
JOIN 
    RecentUsers ru ON pd.OwnerUserId = ru.UserId
WHERE 
    ru.RecentRank <= 10
ORDER BY 
    pd.Score DESC, pd.TotalVotes DESC
LIMIT 50;

-- In this complex query, we're selecting the top-ranked questions from the last year based on their Score, 
-- along with user details, including their VoteSentiment based on cumulative votes received.
-- We're also incorporating the count of comments on these posts and limiting the results to the top 50 questions.
