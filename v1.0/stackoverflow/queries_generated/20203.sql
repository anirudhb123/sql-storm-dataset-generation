WITH UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(u.Reputation) OVER (PARTITION BY u.Id) AS AvgReputation
    FROM
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostHistoryCounts AS (
    SELECT
        ph.PostId,
        COUNT(ph.Id) AS HistoryCount,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM
        PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        p.CreationDate,
        ph.CreationDate AS ClosedDate
    FROM 
        Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        ph.PostHistoryTypeId = 10 AND 
        ph.Comment IS NOT NULL
),
TopUsers AS (
    SELECT 
        UserId, 
        SUM(COALESCE(bp.FavoriteCount, 0)) AS TotalFavorites
    FROM 
        Users u
    LEFT JOIN Badges bp ON u.Id = bp.UserId
    GROUP BY UserId
    ORDER BY TotalFavorites DESC
    LIMIT 10
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.QuestionCount,
    ups.AnswerCount,
    phc.HistoryCount,
    phc.HistoryTypes,
    COALESCE(cp.ClosedDate, 'No Closure') AS ClosureDate,
    tu.TotalFavorites
FROM 
    UserPostStats ups
LEFT JOIN 
    PostHistoryCounts phc ON ups.UserId = phc.PostId
LEFT JOIN 
    ClosedPosts cp ON cp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ups.UserId)
LEFT JOIN 
    TopUsers tu ON ups.UserId = tu.UserId
WHERE 
    ups.AvgReputation > 100 AND 
    (ups.PostCount > 0 OR tu.TotalFavorites IS NOT NULL)
ORDER BY 
    ups.PostCount DESC, 
    ups.DisplayName
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
