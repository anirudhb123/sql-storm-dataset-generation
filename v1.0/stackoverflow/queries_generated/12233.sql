WITH Benchmark AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        COALESCE(SUM(b.Reputation), 0) AS UserReputation,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate
)
SELECT 
    *,
    (UpVotes - DownVotes) AS NetVotes,
    (UserReputation / NULLIF(CommentCount, 0)) AS ReputationPerComment
FROM 
    Benchmark
ORDER BY 
    CreationDate DESC;
