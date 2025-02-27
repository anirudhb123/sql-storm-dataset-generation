WITH UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        RANK() OVER (ORDER BY u.Reputation DESC) as ReputationRank
    FROM Users u
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(AVG(v.BountyAmount), 0) AS AverageBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    GROUP BY p.Id
),
TopPosts AS (
    SELECT
        pd.PostId,
        pd.Title,
        pd.PostCreationDate,
        pd.ViewCount,
        pd.CommentCount,
        ur.DisplayName,
        ur.Reputation,
        pd.AverageBounty,
        ROW_NUMBER() OVER (PARTITION BY ur.UserId ORDER BY pd.ViewCount DESC) AS RN
    FROM PostDetails pd
    JOIN UserReputation ur ON pd.OwnerUserId = ur.UserId
    WHERE pd.ViewCount > 100 -- Only consider posts with more than 100 views
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.PostCreationDate,
    tp.ViewCount,
    tp.CommentCount,
    tp.DisplayName AS OwnerDisplayName,
    tp.Reputation,
    tp.AverageBounty
FROM TopPosts tp
WHERE tp.RN <= 5
ORDER BY tp.Reputation DESC, tp.ViewCount DESC;

-- Inclusion of NULL logic with COALESCE to set the average bounty as 0 if no bounties exist
-- The output lists the top 5 posts for each user with sufficient views, 
-- showing detailed information about post owner and reputation, while using window functions

