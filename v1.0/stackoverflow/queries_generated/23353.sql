WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
), 
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes,
        u.DownVotes,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(AVG(p.ViewCount), 0) AS AvgViewCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
), 
TopBadgedUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        u.BadgeCount,
        RANK() OVER (ORDER BY u.BadgeCount DESC, u.Reputation DESC) AS BadgeRank
    FROM 
        UserStatistics u
    WHERE 
        u.BadgeCount > 0
), 
PostViews AS (
    SELECT 
        ph.PostId,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM 
        PostHistory ph
    LEFT JOIN 
        Votes v ON ph.PostId = v.PostId
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    u.DisplayName AS Author,
    us.AvgViewCount,
    us.TotalScore,
    tb.BadgeCount AS AuthorBadgeCount,
    COALESCE(pv.CloseCount, 0) AS PostCloseCount,
    pv.TotalVotes AS PostTotalVotes
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserStatistics us ON u.Id = us.UserId
LEFT JOIN 
    TopBadgedUsers tb ON u.DisplayName = tb.DisplayName
LEFT JOIN 
    PostViews pv ON rp.PostId = pv.PostId
WHERE 
    rp.Rank <= 10
    AND (us.TotalScore > 100 OR tb.BadgeRank IS NOT NULL)
ORDER BY 
    rp.CreationDate DESC, rp.Score DESC;

This query utilizes Common Table Expressions (CTEs) to rank posts based on their score and view count within the last year. It aggregates user statistics, including badges and voting behaviors. The final selection utilizes a variety of outer joins, correlated subqueries, and case statements to provide a complex overview of top-performing posts and their authors while filtering out those who do not meet certain criteria. The use of COALESCE for dealing with NULL values and the ranking for badge counts adds additional intricacy and depth to the query.
