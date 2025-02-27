
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
        AND p.Score > 0
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(ISNULL(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS TotalUpVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.CreationDate >= DATEADD(year, -2, '2024-10-01 12:34:56')
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CONCAT(pht.Name, ': ', ph.Comment), '; ') AS HistoryComments,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= DATEADD(month, -6, '2024-10-01 12:34:56')
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    u.DisplayName AS OwnerName,
    ua.TotalPosts,
    ua.TotalScore,
    COALESCE(phd.HistoryComments, 'No edits or comments') AS EditHistory,
    phd.HistoryCount AS TotalHistory,
    CASE 
        WHEN ua.TotalScore > 100 THEN 'Expert Contributor'
        WHEN ua.TotalPosts > 50 THEN 'Regular Contributor'
        ELSE 'New Contributor'
    END AS ContributorType
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.AcceptedAnswerId = u.Id
LEFT JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    rp.RankByScore <= 10
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
