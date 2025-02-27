WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
CteJoin AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        rb.PostId,
        rb.Title,
        rb.CreationDate,
        rb.Score,
        rb.CommentCount,
        ub.BadgeCount,
        ub.HighestBadgeClass,
        COALESCE(rb.TotalUpVotes - rb.TotalDownVotes, 0) AS NetScore
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rb ON u.Id = rb.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    cj.UserId,
    cj.DisplayName,
    cj.Reputation,
    ARRAY_AGG(DISTINCT cj.Title) FILTER (WHERE cj.Title IS NOT NULL) AS UserPostTitles,
    SUM(CASE WHEN cj.BadgeCount IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges,
    MAX(cj.HighestBadgeClass) AS HighestBadgeClass,
    COUNT(cj.PostId) AS TotalPosts,
    AVG(cj.NetScore) AS AverageNetScore
FROM 
    CteJoin cj
GROUP BY 
    cj.UserId, cj.DisplayName, cj.Reputation
HAVING 
    COUNT(cj.PostId) > 2 AND 
    AVG(cj.NetScore) > 0
ORDER BY 
    AverageNetScore DESC NULLS LAST;
