WITH RecursivePostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.CreationDate AS HistoryDate,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (1, 4, 10)  -- initial title, edited title, closed
),
LatestPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- only count bounty votes
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'  -- posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.LastActivityDate
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  -- closed
    GROUP BY 
        ph.PostId
)
SELECT 
    lp.Title,
    lp.CreationDate,
    lp.LastActivityDate,
    lp.CommentCount,
    lp.TotalBounty,
    u.DisplayName AS AuthorName,
    ua.TotalViews,
    ua.TotalScore,
    ua.PostCount,
    u.IsModeratorOnly,
    CASE 
        WHEN cp.LastClosedDate IS NOT NULL THEN TRUE 
        ELSE FALSE 
    END AS IsClosed,
    RANK() OVER (ORDER BY lp.TotalBounty DESC) AS BountyRank
FROM 
    LatestPosts lp
JOIN 
    Users u ON lp.OwnerUserId = u.Id
LEFT JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    ClosedPosts cp ON lp.Id = cp.PostId
WHERE 
    (lp.CommentCount > 0 OR u.Reputation > 1000)  -- condition for receiving results
ORDER BY 
    IsClosed DESC,
    lp.TotalBounty DESC,
    lp.LastActivityDate DESC;
