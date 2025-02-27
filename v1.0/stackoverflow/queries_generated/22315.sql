WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(SUBSTRING(p.Tags FROM '\#(.*?)\#'), 'No Tags') AS MainTag
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(month, -6, GETDATE())
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation IS NOT NULL
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT crt.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON ph.Comment IS NOT NULL AND ph.PostHistoryTypeId = 10 AND CAST(ph.Comment AS INT) = crt.Id
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    us.DisplayName,
    us.Reputation,
    rp.Rank,
    us.PostCount,
    us.PositivePosts,
    us.AverageScore,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    cp.CloseReasons
FROM 
    RankedPosts rp
JOIN 
    UserStats us ON rp.OwnerUserId = us.UserId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    us.Reputation > 100 
    AND rp.Rank <= 5 
    AND (rp.Score IS NOT NULL OR rp.MainTag NOT LIKE 'No Tags')
ORDER BY 
    rp.Score DESC, us.Reputation DESC;

WITH PossibleDuplicates AS (
    SELECT 
        p1.Id AS OriginalPostId,
        p2.Id AS DuplicatePostId,
        pl.LinkTypeId
    FROM 
        Posts p1
    JOIN 
        PostLinks pl ON p1.Id = pl.PostId
    JOIN 
        Posts p2 ON pl.RelatedPostId = p2.Id
    WHERE 
        pl.LinkTypeId = 3
)
SELECT 
    OriginalPostId,
    DuplicatePostId
FROM 
    PossibleDuplicates
WHERE 
    EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = DuplicatePostId 
        AND v.VoteTypeId IN (3, 4) -- Downmod or Offensive
    )
ORDER BY 
    OriginalPostId;

-- Cross join to find users whose posts have been closed but have an above-average reputation
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    p.Title
FROM 
    Users u
CROSS JOIN 
    Posts p
LEFT JOIN 
    ClosedPosts cp ON p.Id = cp.PostId
WHERE 
    u.Reputation > (SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL)
    AND cp.PostId IS NOT NULL;
