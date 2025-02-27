WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS VoteBalance
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenCount,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title
)
SELECT 
    u.DisplayName,
    p.Title,
    pa.CommentCount,
    pa.CloseCount,
    pa.ReopenCount,
    uvs.UpVotes,
    uvs.DownVotes,
    uvs.VoteBalance,
    COALESCE(pa.LastHistoryDate, 'No Activity') AS LastActivity,
    CASE 
        WHEN pa.CloseCount > 0 THEN 'Closed'
        WHEN pa.ReopenCount > 0 THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus
FROM 
    PostActivity pa
JOIN 
    Users u ON pa.OwnerUserId = u.Id
JOIN 
    UserVoteSummary uvs ON u.Id = uvs.UserId
WHERE 
    u.Reputation >= 1000
    AND pa.CommentCount > 5
ORDER BY 
    uvs.VoteBalance DESC,
    pa.LastHistoryDate DESC
FETCH FIRST 10 ROWS ONLY;
