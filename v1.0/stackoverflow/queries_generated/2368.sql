WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PostAnswerStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(DISTINCT p.Id) AS AnswerCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2 
    AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    uvs.UpVotes,
    uvs.DownVotes,
    pas.AnswerCount,
    pas.AvgScore,
    cp.CloseCount,
    COALESCE(cp.CloseReasons, 'None') AS CloseReasonSummary
FROM 
    UserVoteStats uvs
LEFT JOIN 
    PostAnswerStats pas ON uvs.UserId = pas.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON uvs.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cp.PostId LIMIT 1)
WHERE 
    uvs.TotalVotes > 50
ORDER BY 
    uvs.UpVotes DESC, uvs.DownVotes ASC
LIMIT 50;
