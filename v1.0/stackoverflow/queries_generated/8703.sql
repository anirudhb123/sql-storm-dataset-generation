WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(ans.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts ans ON p.Id = ans.ParentId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id
),
TopRatedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.UpVoteCount) AS TotalUpVotes,
        SUM(rp.DownVoteCount) AS TotalDownVotes
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.PostId = u.Id
    GROUP BY 
        u.Id
    HAVING 
        COUNT(rp.PostId) >= 5
)
SELECT 
    u.DisplayName,
    u.TotalScore,
    u.TotalUpVotes,
    u.TotalDownVotes,
    (u.TotalUpVotes - u.TotalDownVotes) AS NetVotes,
    rh.UserPostRank
FROM 
    TopRatedUsers u
JOIN 
    RankedPosts rh ON rh.PostId IN (SELECT PostId FROM RankedPosts WHERE OwnerUserId = u.UserId)
ORDER BY 
    u.TotalScore DESC, NetVotes DESC
LIMIT 10;
