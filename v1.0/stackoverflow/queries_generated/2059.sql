WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8 -- BountyStart Votes
    GROUP BY 
        u.Id
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
PopularTags AS (
    SELECT 
        t.TagName,
        t.Count,
        ROW_NUMBER() OVER (ORDER BY t.Count DESC) AS PopularityRank
    FROM 
        Tags t
    WHERE 
        t.IsModeratorOnly = 0
    ORDER BY 
        t.Count DESC
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.Reputation,
    u.TotalBounties,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    (SELECT STRING_AGG(tag.TagName, ', ') 
     FROM LATERAL (
         SELECT t.TagName
         FROM Tags t 
         WHERE t.Id IN (SELECT UNNEST(string_to_array(p.Tags, ','))::int) 
         LIMIT 5
     ) AS tag) AS TopTags
FROM 
    RankedPosts p
JOIN 
    UserReputation u ON p.OwnerUserId = u.UserId
LEFT JOIN 
    PostComments pc ON p.PostId = pc.PostId
WHERE 
    u.Reputation > 1000 -- Only users with a reputation above 1000
    AND p.rn = 1 -- Most recent question for each user
ORDER BY 
    u.TotalBounties DESC, p.Score DESC
LIMIT 10;
