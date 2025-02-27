WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.Score IS NOT NULL
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
        LEFT JOIN Votes v ON u.Id = v.UserId
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
        JOIN CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS varchar)
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
ScoreAggregates AS (
    SELECT 
        p.OwnerUserId,
        AVG(p.Score) AS AvgScore,
        SUM(COALESCE(c.Score, 0)) AS TotalComments,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
        LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.OwnerUserId
)

SELECT 
    us.UserId,
    us.DisplayName,
    COALESCE(rp.Title, 'No Posts Yet') AS PostTitle,
    rp.Score AS PostScore,
    rp.CommentCount AS PostCommentCount,
    us.TotalBounty,
    us.BadgeCount,
    us.LastBadgeDate,
    ca.AvgScore AS UserAvgScore,
    ca.TotalComments AS UserTotalComments,
    ca.VoteCount AS UserVoteCount,
    ca.HistoryCount AS UserHistoryCount,
    cp.CloseReasons AS PostCloseReasons,
    cp.LastClosedDate AS PostLastClosedDate
FROM 
    UserStats us
    LEFT JOIN RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.ScoreRank = 1 
    LEFT JOIN ScoreAggregates ca ON us.UserId = ca.OwnerUserId
    LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    us.TotalBounty > 0 
    OR us.BadgeCount > 0
ORDER BY 
    us.TotalBounty DESC, 
    us.BadgeCount DESC, 
    us.LastBadgeDate DESC;

This SQL query utilizes multiple advanced SQL constructs including Common Table Expressions (CTEs), window functions, aggregation, outer joins, string aggregation, and filtering with `COALESCE` for handling NULL values. It performs a comprehensive analysis of users who have engaged with posts, particularly focusing on their activities related to remarks, accolades, and the closure of posts they have interacted with, ensuring it captures a detailed profile of user contributions within the last year.
