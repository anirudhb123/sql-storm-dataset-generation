WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as rn,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate < NOW() - INTERVAL '1 year'
        AND p.ViewCount > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'High'
            WHEN u.Reputation >= 100 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationCategory
    FROM 
        Users u
),
CommentsCount AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.Upvotes,
        rp.Downvotes,
        COALESCE(cc.TotalComments, 0) AS CommentCount,
        ur.DisplayName,
        ur.ReputationCategory
    FROM 
        RankedPosts rp
    JOIN 
        Users ur ON rp.OwnerUserId = ur.Id
    LEFT JOIN 
        CommentsCount cc ON rp.PostId = cc.PostId
    WHERE 
        rp.rn = 1
)

SELECT
    fs.PostId,
    fs.Title,
    fs.ReputationCategory,
    fs.CreationDate,
    fs.Score - fs.Downvotes + fs.Upvotes AS NetScore,
    COALESCE(fs.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN fs.ReputationCategory = 'High' AND fs.Score > 50 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserType,
    CASE 
        WHEN fs.ViewCount IS NOT NULL THEN 'Viewed'
        ELSE 'Not Viewed'
    END AS ViewStatus,
    NULLIF(fs.Title, '') AS ValidatedTitle,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostsCount
FROM 
    FinalStats fs
LEFT JOIN 
    PostLinks pl ON fs.PostId = pl.PostId
GROUP BY 
    fs.PostId, fs.Title, fs.ReputationCategory, fs.CreationDate, fs.Score, fs.ViewCount, fs.CommentCount
HAVING 
    COUNT(DISTINCT pl.RelatedPostId) > 0 OR fs.CommentCount > 0
ORDER BY 
    fs.Score DESC, fs.ReputationCategory ASC;
