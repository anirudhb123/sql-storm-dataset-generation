WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS NewestEntry
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -3, GETDATE()) 
        AND p.Score IS NOT NULL
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        AVG(COALESCE(p.AnswerCount, 0)) AS AvgAnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons,
        MIN(ph.CreationDate) AS FirstCloseDate
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON cr.Id = CAST(ph.Comment AS INT)
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.TotalViews,
    us.TotalScore,
    us.AvgAnswerCount,
    COALESCE(pcr.CloseReasons, 'No close reasons') AS CloseReasons,
    pcr.FirstCloseDate
FROM 
    RankedPosts rp
LEFT JOIN 
    UserPostStats us ON rp.PostId = us.UserId
LEFT JOIN 
    PostCloseReasons pcr ON rp.PostId = pcr.PostId
WHERE 
    rp.RankScore <= 5 -- Top 5 high scoring posts per type
    AND (rp.AnswerCount > 0 OR rp.CommentCount > 10) -- Posts with answers or many comments
    AND us.Reputation > (SELECT AVG(Reputation) FROM Users) -- Above average reputation
ORDER BY 
    rp.CreationDate DESC, rp.Score DESC;
