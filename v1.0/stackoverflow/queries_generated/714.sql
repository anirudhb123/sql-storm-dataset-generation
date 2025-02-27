WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ClosedVersion
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Posts closed
),
FinalResult AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        u.DisplayName,
        us.Reputation,
        us.QuestionCount,
        us.TotalScore,
        us.TotalBounty,
        cp.CreationDate AS ClosedDate,
        cp.Comment AS CloseReason
    FROM 
        RankedPosts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        UserStats us ON u.Id = us.UserId
    LEFT JOIN 
        ClosedPosts cp ON p.Id = cp.PostId AND cp.ClosedVersion = 1
    WHERE 
        p.Rank <= 3
)
SELECT 
    f.Id,
    f.Title,
    f.CreationDate,
    f.DisplayName,
    f.Reputation,
    f.QuestionCount,
    f.TotalScore,
    f.TotalBounty,
    COALESCE(f.ClosedDate, 'Not Closed') AS ClosedDate,
    COALESCE(f.CloseReason, 'No reason provided') AS CloseReason
FROM 
    FinalResult f
ORDER BY 
    f.TotalScore DESC, 
    f.CreationDate ASC;
