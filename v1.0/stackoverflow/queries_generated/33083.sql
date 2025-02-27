WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts created in the last year
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment AS EditComment,
        PHT.Name AS HistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        PHT.Id IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
),
RecentChanges AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS ChangesCount,
        STRING_AGG(CONCAT(ph.UserDisplayName, ' (', ph.EditComment, ')'), '; ') AS ChangeDetails
    FROM 
        PostHistoryDetails ph
    WHERE 
        ph.CreationDate >= DATEADD(month, -3, GETDATE()) -- Changes made in the last 3 months
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerUserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.QuestionsCount,
    us.AnswersCount,
    us.AverageScore,
    rc.ChangesCount,
    rc.ChangeDetails
FROM 
    RankedPosts rp
LEFT JOIN 
    UserStatistics us ON rp.OwnerUserId = us.UserId
LEFT JOIN 
    RecentChanges rc ON rp.PostId = rc.PostId
WHERE 
    rp.UserPostRank <= 5 -- Show only the last 5 posts of each user
ORDER BY 
    rp.CreationDate DESC;
