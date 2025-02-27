WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Selecting only questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        Posts a ON p.ParentId = a.Id
    INNER JOIN 
        RecursivePosts rp ON a.Id = rp.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000  -- Consider users with reputation above 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 24)  -- Title and Body edits
    GROUP BY 
        ph.PostId
),
AggregatedData AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.ViewCount,
        COALESCE(uh.EditCount, 0) AS EditCount,
        COALESCE(uh.FirstEditDate, 'No Edits') AS FirstEditDate,
        COALESCE(uh.LastEditDate, 'No Edits') AS LastEditDate,
        u.DisplayName AS TopUser
    FROM 
        RecursivePosts rp
    LEFT JOIN 
        PostHistoryStats uh ON rp.Id = uh.PostId
    LEFT JOIN 
        TopUsers u ON u.PostCount = (
            SELECT MAX(PostCount) 
            FROM TopUsers
        )
)
SELECT 
    ad.PostId,
    ad.Title,
    ad.ViewCount,
    ad.EditCount,
    ad.FirstEditDate,
    ad.LastEditDate,
    ad.TopUser,
    ROW_NUMBER() OVER (PARTITION BY ad.TopUser ORDER BY ad.ViewCount DESC) AS Rank
FROM 
    AggregatedData ad
ORDER BY 
    ad.ViewCount DESC;
