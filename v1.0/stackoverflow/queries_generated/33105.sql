WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        Title,
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.CreationDate,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT v.PostId) AS VoteCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostVoteDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COALESCE(vs.TotalVotes, 0) AS TotalVotes,
        COALESCE(b.TotalBounty, 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS TotalVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) vs ON p.Id = vs.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(BountyAmount) AS TotalBounty
        FROM 
            Votes
        WHERE 
            VoteTypeId IN (8, 9) -- Only include BountyStart and BountyClose
        GROUP BY 
            PostId
    ) b ON p.Id = b.PostId
),
PostHistoryStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
FinalStats AS (
    SELECT 
        ph.PostId,
        pv.Title,
        pv.Score,
        pv.TotalVotes,
        pv.TotalBounty,
        COALESCE(ps.EditCount, 0) AS EditCount,
        NULLIF(ps.LastEditDate, '1900-01-01') AS LastEditDate,
        COALESCE(r.Level, 0) AS PostLevel
    FROM 
        PostVoteDetails pv
    LEFT JOIN 
        PostHistoryStats ps ON pv.PostId = ps.PostId
    LEFT JOIN 
        RecursivePostHierarchy r ON pv.PostId = r.Id
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalBounty,
    u.VoteCount,
    u.AvgReputation,
    f.*
FROM 
    UserReputation u
JOIN 
    FinalStats f ON u.UserId = (SELECT OwnerUserId 
                                 FROM Posts 
                                 WHERE Id = f.PostId)
WHERE 
    f.Score > 0 
ORDER BY 
    u.TotalBounty DESC, 
    f.Score DESC;
