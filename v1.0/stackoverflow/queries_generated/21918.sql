WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 END), 0) AS VoteBalance
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.Score
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostsWithHistory AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS HistoryDate,
        p.Title,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS LatestEditDate,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId, ph.UserDisplayName, p.Title, ph.CreationDate
),
FinalReport AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.PostId) AS TotalPosts,
        SUM(COALESCE(pp.VoteBalance, 0)) AS TotalVotes,
        COALESCE(b.BadgeCount, 0) AS TotalBadges,
        COALESCE(pwh.EditCount, 0) AS TotalEdits,
        MAX(pp.CreationDate) AS LastPostDate,
        COUNT(DISTINCT CASE WHEN pp.PostRank = 1 THEN pp.PostId END) AS LatestPostCount,
        CASE 
            WHEN COUNT(DISTINCT pp.PostId) > 10 THEN 'High Contributor'
            WHEN COUNT(DISTINCT pp.PostId) BETWEEN 5 AND 10 THEN 'Moderate Contributor'
            ELSE 'New Contributor'
        END AS ContributorLevel
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts pp ON u.Id = pp.OwnerUserId
    LEFT JOIN 
        UserBadges b ON u.Id = b.UserId
    LEFT JOIN 
        PostsWithHistory pwh ON pp.PostId = pwh.PostId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT pp.PostId) > 0
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalVotes,
    TotalBadges,
    TotalEdits,
    LastPostDate,
    LatestPostCount,
    ContributorLevel
FROM 
    FinalReport
ORDER BY 
    TotalVotes DESC, LastPostDate DESC;
