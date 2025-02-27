WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE 
            WHEN u.Reputation > 10000 THEN 'High'
            WHEN u.Reputation BETWEEN 1000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM 
        Users u
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        COALESCE(pc.CommentCount, 0) AS TotalComments,
        ur.ReputationCategory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.Rank = 1
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.TotalComments,
    fp.ReputationCategory,
    CASE 
        WHEN fp.TotalComments > 10 THEN 'Highly Discussed'
        WHEN fp.TotalComments BETWEEN 5 AND 10 THEN 'Moderately Discussed'
        ELSE 'Less Discussed'
    END AS DiscussionLevel
FROM 
    FilteredPosts fp
WHERE 
    fp.ReputationCategory = 'High' OR fp.Score > 50
ORDER BY 
    fp.Score DESC, fp.CreationDate DESC
LIMIT 100;
