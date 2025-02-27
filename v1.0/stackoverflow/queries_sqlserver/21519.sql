
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        ISNULL((SELECT COUNT(*) 
                FROM Votes v 
                WHERE v.PostId = p.Id AND v.VoteTypeId IN (2, 3)), 0) AS TotalVotes,
        LEN(REPLACE(COALESCE(p.Tags, ''), '><', '')) - LEN(REPLACE(COALESCE(p.Tags, ''), '>', '')) + 1 AS TagCount
    FROM 
        Posts p
    WHERE 
        p.ViewCount IS NOT NULL
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        r.OwnerUserId,
        AVG(r.Score) AS AvgScore,
        SUM(r.ViewCount) AS TotalViews,
        COUNT(*) AS PostsCount,
        COUNT(CASE WHEN r.Rank = 1 THEN 1 END) AS AcceptedAnswers
    FROM 
        RankedPosts r
    WHERE 
        r.Rank <= 10
    GROUP BY 
        r.OwnerUserId
),
UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ISNULL(b.Name, 'No Badge') AS BadgeName,
        b.Class AS BadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > (SELECT AVG(Reputation) FROM Users)
),
RecentCloseReasons AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
        AND ph.CreationDate >= DATEADD(MONTH, DATEDIFF(MONTH, 0, CAST('2024-10-01 12:34:56' AS DATETIME)), 0)
    GROUP BY 
        ph.PostId, ph.Comment
),
FinalResults AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ps.AvgScore,
        ps.TotalViews,
        ps.PostsCount,
        ps.AcceptedAnswers,
        CASE 
            WHEN rc.CloseCount IS NULL THEN 'Not Closed' 
            ELSE 'Closed' 
        END AS RecentCloseStatus,
        rc.Comment AS RecentCloseComment
    FROM 
        UserWithBadges ub
    JOIN 
        PostStats ps ON ub.UserId = ps.OwnerUserId
    LEFT JOIN 
        RecentCloseReasons rc ON rc.PostId = (SELECT TOP 1 Id FROM Posts WHERE OwnerUserId = ub.UserId ORDER BY Id DESC)
)
SELECT 
    UserId,
    DisplayName,
    AvgScore,
    TotalViews,
    PostsCount,
    AcceptedAnswers,
    RecentCloseStatus,
    RecentCloseComment
FROM 
    FinalResults
WHERE 
    AvgScore > 0
ORDER BY 
    AvgScore DESC, TotalViews DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
