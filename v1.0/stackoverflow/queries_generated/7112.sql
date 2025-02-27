WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVoteCount,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) OVER (PARTITION BY p.Id) AS EditHistoryCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.UpVoteCount) AS TotalUpVotes,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.EditHistoryCount) AS TotalEdits,
        COUNT(rp.PostId) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalScore,
    us.TotalUpVotes,
    us.TotalComments,
    us.TotalEdits,
    us.TotalPosts,
    RANK() OVER (ORDER BY us.TotalScore DESC) AS Rank
FROM 
    UserStats us
WHERE 
    us.TotalPosts > 0
ORDER BY 
    us.TotalScore DESC
LIMIT 10;
