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
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.Score > 0
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS TotalUpVotes,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '2 years'
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name || ': ' || ph.Comment, '; ') AS HistoryComments,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
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
