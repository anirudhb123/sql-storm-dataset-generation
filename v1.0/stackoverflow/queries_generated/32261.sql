WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBountyAmount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY SUM(rp.AnswerCount) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ph.PostHistoryTypeId
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
),
ActivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        CASE 
            WHEN cp.PostId IS NOT NULL THEN 'Closed' 
            ELSE 'Active' 
        END AS Status,
        rp.AnswerCount,
        rp.TotalBountyAmount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.Id = cp.PostId
    JOIN 
        Posts p ON rp.Id = p.Id
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    ap.Title,
    ap.Status,
    ap.AnswerCount,
    ap.TotalBountyAmount
FROM 
    TopUsers u
JOIN 
    ActivePosts ap ON u.UserId = ap.OwnerUserId
WHERE 
    u.UserRank <= 10  -- Top 10 users based on answer count
ORDER BY 
    u.UserRank, ap.AnswerCount DESC;

-- Additional metrics for performance benchmarking
WITH SummaryData AS (
    SELECT 
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        COUNT(DISTINCT a.Id) AS TotalAnswers,
        COUNT(DISTINCT cp.PostId) AS TotalClosedPosts,
        SUM(v.BountyAmount) AS TotalBountyDistributed
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        ClosedPosts cp ON p.Id = cp.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    WHERE 
        p.PostTypeId = 1
)
SELECT 
    TotalQuestions,
    TotalAnswers,
    TotalClosedPosts,
    TotalBountyDistributed
FROM 
    SummaryData;

-- Performance benchmark query to get avg view count of top posts
SELECT 
    AVG(p.ViewCount) AS AvgViewCount
FROM 
    Posts p
WHERE 
    p.PostTypeId = 1
AND 
    p.ViewCount IS NOT NULL
AND 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year';
