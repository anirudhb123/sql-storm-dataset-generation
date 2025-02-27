
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AnswerCount,
        p.Score,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL 1 YEAR
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
        AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerUserId,
        (UNIX_TIMESTAMP('2024-10-01 12:34:56') - UNIX_TIMESTAMP(rp.CreationDate)) / 86400 AS AgeInDays,
        COALESCE(phs.EditCount, 0) AS EditCount,
        phs.ClosedDate
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistorySummary phs ON rp.Id = phs.PostId
    WHERE 
        rp.UserPostRank = 1
)
SELECT 
    tu.DisplayName,
    tp.Title,
    tp.Score,
    tp.AgeInDays,
    tp.EditCount,
    CASE 
        WHEN tp.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    TopPosts tp
JOIN 
    TopUsers tu ON tp.OwnerUserId = tu.UserId
ORDER BY 
    tp.Score DESC,
    tp.AgeInDays ASC;
