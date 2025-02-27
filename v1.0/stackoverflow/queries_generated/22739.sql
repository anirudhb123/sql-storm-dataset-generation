WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        COALESCE(CAST(NULLIF(p.Body, '') AS TEXT), 'No content available') AS BodyContent,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        p.CreationDate >= '2023-01-01' 
        AND (p.Score > 0 OR p.ViewCount > 100)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, pt.Name
),

CloseReasons AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(cr.Name) AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
        AND ph.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        ph.PostId
),

UserScores AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Rank,
    rp.BodyContent,
    coalesce(cr.CloseReasonNames, 'No close reason') AS CloseReasons,
    us.UserId,
    us.UpVotes,
    us.DownVotes,
    us.TotalPosts,
    us.AvgReputation,
    CASE 
        WHEN us.TotalPosts > 10 THEN 'Experienced Contributor'
        ELSE 'New Contributor'
    END AS ContributorLevel
FROM 
    RankedPosts rp
LEFT JOIN 
    CloseReasons cr ON rp.PostId = cr.PostId
LEFT JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    UserScores us ON u.Id = us.UserId
WHERE 
    rp.Rank <= 5 OR rp.Score >= 100
ORDER BY 
    rp.CreationDate DESC;
