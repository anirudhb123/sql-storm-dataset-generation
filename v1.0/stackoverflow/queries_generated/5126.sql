WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.Tags, p.OwnerUserId
),
UserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ARRAY_AGG(rp.PostId) AS PostIds,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.UpVoteCount) AS TotalUpVotes,
        SUM(rp.DownVoteCount) AS TotalDownVotes,
        COUNT(DISTINCT rp.PostId) AS PostCount
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.PostCount,
    up.TotalComments,
    up.TotalUpVotes,
    up.TotalDownVotes,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY up.Reputation) OVER () AS MedianReputation,
    MAX(rp.CreationDate) AS LastPostDate
FROM 
    UserPosts up
JOIN 
    RankedPosts rp ON up.PostIds::int[] && ARRAY[rm.PostId]  -- Find posts for each user
GROUP BY 
    up.UserId, up.DisplayName, up.Reputation
ORDER BY 
    up.Reputation DESC, up.TotalUpVotes DESC
LIMIT 10;

