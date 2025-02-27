WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only include questions
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        ur.Reputation,
        ur.DisplayName,
        phs.CloseReopenCount,
        phs.DeleteUndeleteCount,
        DATEDIFF(MINUTE, phs.FirstEditDate, phs.LastEditDate) AS EditDurationMinutes
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    LEFT JOIN 
        PostHistorySummary phs ON rp.PostId = phs.PostId
    WHERE 
        rp.PostRank = 1
)
SELECT 
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    Reputation,
    DisplayName,
    CloseReopenCount,
    DeleteUndeleteCount,
    EditDurationMinutes,
    CASE 
        WHEN Reputation > 1000 THEN 'Experienced'
        WHEN Reputation BETWEEN 500 AND 1000 THEN 'Moderate'
        ELSE 'Novice'
    END AS UserType
FROM 
    FinalResults
ORDER BY 
    Score DESC, ViewCount DESC;
