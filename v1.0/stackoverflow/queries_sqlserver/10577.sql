
WITH PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST(DATEADD(year, -1, '2024-10-01') AS DATE)
    GROUP BY 
        p.Id, p.Title
),
UserPostSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCount,
        SUM(COALESCE(ph.Id, 0)) AS PostHistoryCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.PostsCount,
    u.PostHistoryCount,
    p.PostId,
    p.Title,
    p.TotalVotes,
    p.Upvotes,
    p.Downvotes
FROM 
    UserPostSummary u
JOIN 
    PostVoteSummary p ON u.PostsCount > 0 
ORDER BY 
    u.PostsCount DESC, p.TotalVotes DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
