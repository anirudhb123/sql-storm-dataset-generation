WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.PostTypeId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL 

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.PostTypeId,
        cte.Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePostCTE cte ON p.ParentId = cte.PostId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        p.Title,
        p.OwnerUserId,
        p.LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId, ph.CreationDate, ph.UserId, p.Title, p.OwnerUserId, p.LastEditDate
),
TopUsers AS (
    SELECT 
        ur.UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC) AS Rank
    FROM 
        UserReputation ur
    JOIN 
        Users u ON ur.UserId = u.Id
)
SELECT 
    cte.Title,
    cte.PostId,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    COALESCE(phd.HistoryTypes, 'No History') AS PostHistoryTypes,
    ROW_NUMBER() OVER (PARTITION BY cte.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
FROM 
    RecursivePostCTE cte
LEFT JOIN 
    Users u ON cte.OwnerUserId = u.Id
LEFT JOIN 
    PostHistoryDetails phd ON cte.PostId = phd.PostId 
WHERE 
    cte.Level = 0
ORDER BY 
    u.Reputation DESC, HistoryRank
LIMIT 50;
