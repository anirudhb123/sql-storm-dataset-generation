WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(b.Class), 0) AS TotalBadgeClass,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId AND ph.PostHistoryTypeId IN (4, 5, 6) -- Edits
    GROUP BY 
        u.Id, u.Reputation
),

PostVoteData AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)

SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    COALESCE(pd.Upvotes, 0) AS TotalUpvotes,
    COALESCE(pd.Downvotes, 0) AS TotalDownvotes,
    u.DisplayName AS OwnerName,
    u.Reputation,
    COALESCE(bad.TotalBadgeClass, 0) AS TotalBadgeClass,
    CASE 
        WHEN TotalUpvotes > TotalDownvotes THEN 'Positive'
        WHEN TotalDownvotes > TotalUpvotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Latest Post'
        ELSE NULL
    END AS PostStatus
FROM 
    RankedPosts rp
JOIN 
    Posts p ON rp.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserReputation bad ON u.Id = bad.UserId
LEFT JOIN 
    PostVoteData pd ON p.Id = pd.PostId
WHERE 
    (bad.Reputation > 1000 OR (bad.EditCount > 5 AND bad.TotalBadgeClass > 0)) -- Active users with badges or high rep
ORDER BY 
    p.CreationDate DESC
FETCH FIRST 10 ROWS ONLY; -- Retrieve top 10 recent posts by criteria
