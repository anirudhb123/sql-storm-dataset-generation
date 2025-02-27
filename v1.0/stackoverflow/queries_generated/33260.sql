WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.AcceptedAnswerId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(rp.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        RankedPosts rp ON rp.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT
        ph.PostId,
        ph.UserId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.UserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalScore,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    MAX(phs.LastEditDate) AS MostRecentEdit,
    SUM(phs.CloseCount) AS TotalClosedPosts,
    SUM(phs.ReopenCount) AS TotalReopenedPosts,
    AVG(rp.CommentCount) AS AvgCommentsPerPost,
    SUM(rp.UpVotes) AS TotalUpVotes,
    SUM(rp.DownVotes) AS TotalDownVotes
FROM 
    UserStats us
LEFT JOIN 
    PostHistoryStats phs ON us.UserId = phs.UserId
LEFT JOIN 
    RankedPosts rp ON rp.Rank = 1
GROUP BY 
    us.UserId, us.DisplayName
HAVING 
    SUM(phs.CloseCount) > 0 OR SUM(phs.ReopenCount) > 0
ORDER BY 
    us.TotalScore DESC, us.DisplayName;
