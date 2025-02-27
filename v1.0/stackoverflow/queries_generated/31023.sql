WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
RecentPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        ub.BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    WHERE 
        rp.CreationDate >= NOW() - INTERVAL '30 days'
),
PostScoreSummary AS (
    SELECT 
        AVG(ViewCount) AS AvgViewCount,
        SUM(Score) AS TotalScore,
        SUM(CommentCount) AS TotalComments,
        SUM(UpVotes - DownVotes) AS NetVotes
    FROM 
        RecentPosts
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    ub.BadgeCount,
    ps.AvgViewCount,
    ps.TotalScore,
    ps.TotalComments,
    ps.NetVotes
FROM 
    RecentPosts rp
CROSS JOIN 
    PostScoreSummary ps
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;

WITH RECURSIVE PostHierarchy AS (
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
        PostHierarchy ph ON p.ParentId = ph.Id
)
SELECT 
    ph.Id AS PostId,
    ph.Title,
    ph.Level
FROM 
    PostHierarchy ph
WHERE 
    ph.Level BETWEEN 1 AND 3
ORDER BY 
    ph.Level, ph.Title;
