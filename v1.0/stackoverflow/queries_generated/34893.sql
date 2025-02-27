WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE
        p.PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        a.CreationDate,
        COALESCE(a.AcceptedAnswerId, -1),
        Level + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursiveCTE r ON a.ParentId = r.PostId
    WHERE 
        a.PostTypeId = 2 -- Only answers
),
VoteStats AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(ps.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
FinalResults AS (
    SELECT 
        r.PostId,
        r.Title,
        r.OwnerUserId,
        r.CreationDate,
        r.AcceptedAnswerId,
        vs.UpVotes,
        vs.DownVotes,
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.BadgeCount,
        us.TotalViews,
        RANK() OVER (PARTITION BY r.Level ORDER BY vs.UpVotes DESC) AS RankByUpvotes,
        ROW_NUMBER() OVER (PARTITION BY r.OwnerUserId ORDER BY r.CreationDate DESC) AS RecentPostRank
    FROM 
        RecursiveCTE r
    LEFT JOIN 
        VoteStats vs ON r.PostId = vs.PostId
    LEFT JOIN 
        UserStats us ON r.OwnerUserId = us.UserId
)
SELECT 
    f.PostId,
    f.Title,
    f.DisplayName,
    f.Reputation,
    f.UpVotes,
    f.DownVotes,
    f.BadgeCount,
    f.TotalViews,
    f.RankByUpvotes,
    f.RecentPostRank
FROM 
    FinalResults f
WHERE 
    f.UpVotes > 0 
    OR f.Reputation > 100
    OR f.BadgeCount > 0
ORDER BY 
    f.UpVotes DESC, f.CreationDate ASC;
