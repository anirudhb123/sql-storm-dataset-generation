WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '6 months' 
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
),
UserParticipations AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(bp.Reputation) AS TotalReputation,
        COUNT(DISTINCT rp.PostId) AS TotalPosts,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.UpVoteCount) AS TotalUpVotes,
        SUM(rp.DownVoteCount) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalReputation,
    up.TotalPosts,
    up.TotalComments,
    up.TotalUpVotes,
    up.TotalDownVotes,
    (up.TotalUpVotes - up.TotalDownVotes) AS NetVotes,
    RANK() OVER (ORDER BY up.TotalPosts DESC) AS PostRanking
FROM 
    UserParticipations up
WHERE 
    up.TotalPosts > 0
ORDER BY 
    NetVotes DESC, TotalReputation DESC
LIMIT 50;
