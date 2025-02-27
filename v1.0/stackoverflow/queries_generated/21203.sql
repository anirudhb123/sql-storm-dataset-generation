WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadgeClass,
        COUNT(v.Id) AS VoteCount,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Users u
        LEFT JOIN Badges b ON u.Id = b.UserId
        LEFT JOIN Votes v ON u.Id = v.UserId
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) >= 10
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ta.TagName,
        tu.DisplayName AS TopUserDisplayName,
        tcu.TotalBadgeClass,
        tu.AverageScore
    FROM 
        RankedPosts rp
        LEFT JOIN LATERAL (
            SELECT 
                UNNEST(STRING_TO_ARRAY(rp.Tags, '> <')) AS TagName 
        ) AS ta ON TRUE
        LEFT JOIN TopUsers tu ON rp.OwnerUserId = tu.UserId
        LEFT JOIN TopUsers tcu ON tu.UserId = tcu.UserId AND tcu.TotalBadgeClass = (SELECT MAX(TotalBadgeClass) FROM TopUsers)
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    CONCAT('User: ', COALESCE(pd.TopUserDisplayName, 'Unspecified'), ' | Badges: ', COALESCE(pd.TotalBadgeClass, 0), ' | Avg Score: ', COALESCE(pd.AverageScore, 0)) AS UserInfo
FROM 
    PostDetails pd
WHERE 
    pd.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1)
    AND pd.ViewCount > (SELECT AVG(ViewCount) FROM Posts WHERE PostTypeId = 1)
    AND pd.TopUserDisplayName IS NOT NULL
ORDER BY 
    pd.Score DESC,
    pd.ViewCount DESC NULLS LAST
LIMIT 50;
