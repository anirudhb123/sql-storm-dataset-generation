WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        pp.UserDisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS TotalUpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users pp ON p.OwnerUserId = pp.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -6, GETDATE())
),
RecentClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS CloseDate,
        T.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes T ON ph.Comment = CAST(T.Id AS VARCHAR) 
    WHERE 
        ph.PostHistoryTypeId = 10 
        AND ph.CreationDate >= DATEADD(MONTH, -6, GETDATE())
),
FinalStats AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.AnswerCount,
        ps.OwnerDisplayName,
        ps.CreationDate,
        ps.TotalUpVotes,
        ps.TotalDownVotes,
        rc.CloseDate,
        rc.CloseReason
    FROM 
        PostStats ps
    LEFT JOIN 
        RecentClosedPosts rc ON ps.PostId = rc.PostId
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.ViewCount,
    fs.AnswerCount,
    fs.OwnerDisplayName,
    fs.CreationDate,
    fs.CloseDate,
    fs.CloseReason,
    (fs.TotalUpVotes - fs.TotalDownVotes) AS NetVotes,
    CASE 
        WHEN fs.CloseDate IS NOT NULL THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus
FROM 
    FinalStats fs
WHERE 
    fs.CloseDate IS NOT NULL OR fs.NetVotes > 10
ORDER BY 
    fs.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
