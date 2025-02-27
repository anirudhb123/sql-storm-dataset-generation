WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY Tags ORDER BY p.CreationDate DESC) AS TagRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT 
             PostId 
         FROM 
             Comments) c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), 
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        pt.Name AS PostType
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = rp.PostId)
    WHERE 
        (rp.Score > 10 OR rp.CommentCount > 5) AND
        rp.TagRank = 1
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        pht.Name AS HistoryType,
        ph.CreationDate AS HistoryDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges,
        AVG(u.Reputation) AS AverageReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate < NOW() - INTERVAL '2 years'
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.CommentCount,
    fp.PostType,
    ARRAY_AGG(DISTINCT ph.HistoryType) AS PostHistoryTypes,
    us.DisplayName AS UserDisplayName,
    us.AverageReputation,
    CASE 
        WHEN us.GoldBadges > 0 THEN 'Gold Contributor'
        WHEN us.SilverBadges > 0 THEN 'Silver Contributor'
        ELSE 'New Contributor'
    END AS ContributorStatus
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistoryData ph ON fp.PostId = ph.PostId
LEFT JOIN 
    Users u ON fp.PostId IN (SELECT ParentId FROM Posts WHERE ParentId IS NOT NULL)
LEFT JOIN 
    UserStatistics us ON u.Id = fp.PostId
GROUP BY 
    fp.PostId, us.DisplayName, us.AverageReputation
HAVING 
    COUNT(DISTINCT ph.HistoryType) > 1 OR 
    MAX(fp.Score) > 50
ORDER BY 
    fp.CreationDate DESC
LIMIT 100;
