WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.OwnerUserId, u.DisplayName
),
RecentBadges AS (
    SELECT 
        b.UserId,
        b.Name,
        ROW_NUMBER() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Badges b
    WHERE 
        b.Date > NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.VoteCount) AS TotalVotes,
        COUNT(DISTINCT rb.UserId) AS RecentBadgesCount,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.CommentCount) DESC) AS Ranking
    FROM 
        Users u
    LEFT JOIN 
        PostStatistics ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        RecentBadges rb ON u.Id = rb.UserId AND rb.BadgeRank <= 3
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalComments DESC
),
ClosedPosts AS (
    SELECT 
        p.Id,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY 
        p.Id
)

SELECT 
    tu.DisplayName,
    tu.TotalComments,
    tu.TotalVotes,
    tu.RecentBadgesCount,
    COALESCE(cp.LastClosedDate, 'Not Closed') AS LastClosedPostDate,
    CASE 
        WHEN tu.TotalVotes > 100 THEN 'Highly Active'
        WHEN tu.TotalVotes BETWEEN 50 AND 100 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS ActivityLevel
FROM 
    TopUsers tu
LEFT JOIN 
    ClosedPosts cp ON tu.Id = cp.Id
WHERE 
    tu.Ranking <= 10
ORDER BY 
    tu.TotalComments DESC;
