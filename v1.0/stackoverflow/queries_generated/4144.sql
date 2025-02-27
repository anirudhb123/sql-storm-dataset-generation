WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = u.Id) AS PostCount,
        (SELECT COUNT(*) FROM Comments WHERE UserId = u.Id) AS CommentCount
    FROM 
        Users u
    WHERE 
        u.Reputation > 100
),
RecentComments AS (
    SELECT 
        c.Id AS CommentId,
        c.PostId,
        c.CreationDate,
        c.UserId,
        c.Text,
        RANK() OVER(PARTITION BY c.PostId ORDER BY c.CreationDate DESC) AS CommentRank
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= NOW() - INTERVAL '7 days'
),
AggregatedData AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(AVG(v.BountyAmount), 0) AS AvgBounty,
        COALESCE(MAX(c.Score), 0) AS MaxCommentScore,
        (SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId = p.PostId) AS LinkCount
    FROM 
        RankedPosts p
    LEFT JOIN 
        Votes v ON p.PostId = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    LEFT JOIN 
        RecentComments c ON p.PostId = c.PostId
    GROUP BY 
        p.PostId, p.Title, p.CreationDate, p.Score, p.ViewCount
)
SELECT 
    ad.PostId,
    ad.Title,
    ad.CreationDate,
    ad.Score,
    ad.ViewCount,
    ad.AvgBounty,
    ad.MaxCommentScore,
    u.Reputation AS UserReputation,
    u.PostCount,
    u.CommentCount
FROM 
    AggregatedData ad
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = ad.PostId)
WHERE 
    ad.Score > 10 
    AND ad.ViewCount > 100
ORDER BY 
    ad.Score DESC, 
    ad.ViewCount ASC
LIMIT 100;
