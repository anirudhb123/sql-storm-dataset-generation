
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        @rank := @rank + 1 AS Rank
    FROM 
        Users u, (SELECT @rank := 0) r
    ORDER BY u.Reputation DESC
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AvgScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
VotingData AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostsWithStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        ps.PostCount,
        ps.TotalViews,
        ps.AvgScore,
        COALESCE(vd.UpVotes, 0) AS UpVotes,
        COALESCE(vd.DownVotes, 0) AS DownVotes,
        COALESCE(ur.Reputation, 0) AS UserReputation,
        ur.Rank AS UserRank,
        p.CreationDate,
        @post_rank := IF(@current_owner = p.OwnerUserId, @post_rank + 1, 1) AS PostRank,
        @current_owner := p.OwnerUserId
    FROM 
        Posts p, (SELECT @post_rank := 0, @current_owner := NULL) r
    LEFT JOIN 
        PostStatistics ps ON p.OwnerUserId = ps.OwnerUserId
    LEFT JOIN 
        VotingData vd ON p.Id = vd.PostId
    LEFT JOIN 
        UserReputation ur ON p.OwnerUserId = ur.UserId
    ORDER BY p.OwnerUserId, p.CreationDate DESC
)
SELECT 
    pws.Title,
    pws.PostCount,
    pws.TotalViews,
    pws.AvgScore,
    pws.UpVotes,
    pws.DownVotes,
    pws.UserReputation,
    pws.UserRank,
    pws.CreationDate,
    pws.PostRank
FROM 
    PostsWithStatistics pws
WHERE 
    pws.UserReputation > 1000
    AND pws.PostRank = 1
ORDER BY 
    pws.UserReputation DESC, 
    pws.TotalViews DESC;
