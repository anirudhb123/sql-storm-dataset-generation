WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (6, 4) THEN 1 ELSE 0 END), 0) AS CloseVoteCount
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) 
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
PostOwnership AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(cp.CommentCount, 0)) AS TotalComments,
        SUM(COALESCE(v.UpVoteCount, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.CloseVoteCount, 0)) AS TotalCloseVotes
    FROM 
        Users u
        LEFT JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
        LEFT JOIN (SELECT OwnerUserId, CommentCount FROM (SELECT OwnerUserId, COUNT(*) AS CommentCount FROM Comments GROUP BY OwnerUserId) c) cp ON rp.OwnerUserId = cp.OwnerUserId
        LEFT JOIN (SELECT OwnerUserId, SUM(UpVoteCount) AS UpVoteCount, SUM(CloseVoteCount) AS CloseVoteCount FROM (SELECT OwnerUserId, COUNT(*) AS UpVoteCount FROM Votes WHERE VoteTypeId = 2 GROUP BY OwnerUserId) v1 GROUP BY OwnerUserId) v ON rp.OwnerUserId = v.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    u.DisplayName,
    po.TotalPosts,
    po.TotalComments,
    po.TotalUpVotes,
    po.TotalCloseVotes,
    CASE 
        WHEN po.TotalCloseVotes > 0 THEN 'Needs Attention' 
        ELSE 'Stable' 
    END AS PostStatus
FROM 
    PostOwnership po
    JOIN Users u ON u.Id = po.UserId
WHERE 
    po.TotalPosts > 5
ORDER BY 
    po.TotalUpVotes DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
UNION ALL
SELECT 
    'Total' AS DisplayName, 
    COUNT(*),
    SUM(TotalComments),
    SUM(TotalUpVotes),
    SUM(TotalCloseVotes),
    NULL
FROM 
    PostOwnership;
