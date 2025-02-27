WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'  -- Within the last year
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS CloserDisplayName
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5  -- Active users with more than 5 posts
),
MostActive AS (
    SELECT 
        ua.DisplayName,
        ua.TotalPosts,
        ua.TotalBounties,
        RANK() OVER (ORDER BY ua.TotalPosts DESC) AS UserRank
    FROM 
        ActiveUsers ua
),
QuestionStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score AS QuestionScore,
        rp.ViewCount,
        COALESCE(cp.ClosedDate, '1970-01-01') AS ClosedDate,  -- Use a default date if null
        COALESCE(cp.CloserDisplayName, 'Not Closed') AS CloserDisplayName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.ClosedPostId
)
SELECT 
    qs.Title,
    qs.OwnerDisplayName,
    qs.QuestionScore,
    qs.ViewCount,
    qs.ClosedDate,
    qs.CloserDisplayName,
    ma.DisplayName AS MostActiveUser,
    ma.TotalPosts,
    ma.TotalBounties
FROM 
    QuestionStats qs
JOIN 
    MostActive ma ON ma.UserRank <= 10  -- Top 10 active users
ORDER BY 
    qs.QuestionScore DESC, qs.ViewCount DESC
LIMIT 20;  -- Limit results to 20 top questions
